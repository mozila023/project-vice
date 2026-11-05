shader_type spatial;
render_mode cull_disabled;
uniform sampler2D frond : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
varying float shade;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float reach = length(VERTEX.xz-vec2(1.5,0.0));
	float gust = sin(TIME*1.4+origin.x*0.25+VERTEX.x*0.6)+sin(TIME*2.3+origin.z*0.3+VERTEX.z*0.9)*0.5;
	VERTEX.y += gust*0.022*reach*reach;
	VERTEX.x += gust*0.012*reach*reach;
	// Instanced draws have no vertex colour in this renderer, so baked shade travels in UV2.
	shade = UV2.x;
}

void fragment() {
	vec4 c = texture(frond,UV);
	ALBEDO = c.rgb*shade*vec3(0.92,1.05,0.78);
	ALPHA = min(c.a*1.3,1.0);
	ALPHA_SCISSOR_THRESHOLD = 0.4;
	ALPHA_ANTIALIASING_EDGE = 0.2;
	ALPHA_TEXTURE_COORDINATE = UV*vec2(textureSize(frond,0));
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
	BACKLIGHT = ALBEDO*0.3;
}


