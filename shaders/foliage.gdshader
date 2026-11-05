shader_type spatial;
render_mode cull_disabled;
// Near plant cards: three crossed planes that sway, dissolving out at near_range.
#include "res://shaders/foliage_common.gdshaderinc"
uniform float near_range = 190.0;
uniform float fade_width = 8.0;
uniform float brightness = 0.48;
uniform vec3 view_pos = vec3(0.0);
const float CROWN_HEIGHT = 0.55;
const float CROWN_LIFT = 0.45;
varying vec3 crown_normal;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float d = distance(origin.xz,view_pos.xz);
	fade = 1.0-smoothstep(near_range-fade_width,near_range,d);
	if (fade<=0.0) {
		VERTEX = vec3(0.0);
	} else {
		float sway = sin(TIME*1.1+origin.x*0.3+origin.z*0.2)+sin(TIME*1.9+origin.z*0.4+VERTEX.x*3.0)*0.45;
		VERTEX.x += sway*0.012*VERTEX.y*VERTEX.y;
		VERTEX.z += sway*0.008*VERTEX.y*VERTEX.y;
	}
	// Light the whole plant as one rounded crown; per-card normals show every flat plane as a hard dark rectangle.
	// Set per fragment too: with culling off the engine would flip it on the back of each card.
	// Y stays positive, so the lower crown is lit from the sky rather than turning black underneath.
	vec3 from_centre = vec3(VERTEX.x,max(VERTEX.y-CROWN_HEIGHT,0.0)+CROWN_LIFT,VERTEX.z);
	crown_normal = (MODELVIEW_MATRIX*vec4(from_centre,0.0)).xyz;
	cell_uv = (UV+INSTANCE_CUSTOM.xy)/grid;
	tone = INSTANCE_CUSTOM.z;
}

void fragment() {
	// No dithered fade here: discarding fragments in this shader drew pure white speckles in the Compatibility renderer.
	// Near and far cards overlap by 25 m instead, so the hand-over leaves no holes.
	NORMAL = normalize(crown_normal);
	vec4 source = texture(atlas,cell_uv);
	vec3 albedo = foliage_colour(source.rgb,tone)*brightness;
	ALBEDO = albedo;
	ALPHA = min(source.a*1.25,1.0);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.25;
	ALPHA_TEXTURE_COORDINATE = cell_uv*vec2(textureSize(atlas,0));
	ROUGHNESS = 0.82;
	SPECULAR = 0.1;
	BACKLIGHT = albedo*0.22;
}



