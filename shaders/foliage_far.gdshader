shader_type spatial;
render_mode cull_disabled, skip_vertex_transform;
// Distant plants: one camera-facing quad each. Hidden inside the range of the near meshes.
#include "res://shaders/foliage_common.gdshaderinc"
uniform float near_range = 190.0;
uniform float palm_range = 115.0;
uniform vec3 view_pos = vec3(0.0);

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[1].xyz);
	vec3 to_view = view_pos-origin;
	to_view.y = 0.0;
	float d = length(to_view);
	// Palm cards use atlas cell (0,1).
	bool is_palm = INSTANCE_CUSTOM.x<0.5 && INSTANCE_CUSTOM.y>0.5;
	float begin = is_palm ? palm_range : near_range;
	// Appears 25 m before the near cards leave at begin, so the two overlap and the hand-over leaves no holes.
	fade = smoothstep(begin-25.0,begin-8.0,d);
	vec3 forward = to_view/max(d,0.001);
	vec3 right = vec3(forward.z,0.0,-forward.x);
	vec3 world = origin;
	if (fade>0.0) world += (right*VERTEX.x+vec3(0.0,VERTEX.y,0.0))*size;
	VERTEX = (VIEW_MATRIX*vec4(world,1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX*vec4(right*(UV.x*2.0-1.0)*0.75+vec3(0.0,1.0-UV.y*0.7,0.0)+forward*0.55,0.0)).xyz);
	cell_uv = (UV+INSTANCE_CUSTOM.xy)/grid;
	tone = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec4 source = texture(atlas,cell_uv);
	vec3 albedo = foliage_colour(source.rgb,tone)*0.46;
	ALBEDO = albedo;
	// Mips thin out cut-outs at range, so boost coverage to keep canopies full.
	ALPHA = min(source.a*1.7,1.0);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA_ANTIALIASING_EDGE = 0.25;
	ALPHA_TEXTURE_COORDINATE = cell_uv*vec2(textureSize(atlas,0));
	ROUGHNESS = 0.9;
	SPECULAR = 0.0;
	BACKLIGHT = albedo*0.12;
}



