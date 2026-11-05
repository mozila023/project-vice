shader_type spatial;
render_mode depth_draw_never, specular_schlick_ggx;
// Roads, sampled in world space so curves and chunk borders have no texture seams and no visible tiling.
// COLOR: r paved, g centre line, b edge lines, a end fade. UV: x -1..1 across, y metres along. UV2.x: half width in metres.
uniform sampler2D asphalt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D asphalt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float shoulder = 1.1;
uniform float fade_begin = 640.0;
uniform float fade_end = 880.0;
varying vec3 world_pos;
varying float half_width;
varying float view_dist;

void vertex() {
	world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	view_dist = distance(world_pos,CAMERA_POSITION_WORLD);
	// Rises imperceptibly with distance: keeps the road above the coarse terrain without any depth fighting.
	VERTEX.y += 0.015+view_dist*0.0011;
	half_width = UV2.x;
	TANGENT = vec3(1.0,0.0,0.0);
	BINORMAL = vec3(0.0,0.0,1.0);
}

void fragment() {
	vec2 p = world_pos.xz;
	float across = UV.x*(half_width+shoulder);
	float side = abs(across);
	float blotch = texture(noise_tex,p*0.031).r;
	float grain = texture(noise_tex,p*0.19).g;
	// The tarmac edge wanders a little, as it does on a real patched road.
	float edge = side-half_width+(blotch-0.5)*0.9;

	vec3 tar = mix(texture(asphalt_tex,p*0.24).rgb,texture(asphalt_tex,p.yx*0.067+0.31).rgb,0.42);
	tar *= vec3(0.76,0.76,0.74)*mix(0.82,1.06,blotch);
	// Wheel tracks polish the surface; the margins collect pale dust.
	float wheels = 1.0-smoothstep(0.1,0.42,abs(side/max(half_width,0.1)-0.52));
	tar *= 1.0-wheels*0.07;
	vec3 dust = vec3(0.47,0.43,0.35)*mix(0.86,1.08,grain);
	tar = mix(tar,dust,smoothstep(-1.3,0.2,edge)*0.62);

	vec3 dirt = mix(vec3(0.31,0.26,0.20),vec3(0.46,0.40,0.31),blotch*0.65+grain*0.35);
	dirt = mix(dirt,dirt*0.72,wheels*0.55);
	dirt = mix(dirt,vec3(0.22,0.28,0.12),(1.0-smoothstep(0.0,0.2,side/max(half_width,0.1)))*0.35*grain);

	vec3 col = mix(dirt,tar,COLOR.r);

	// Painted lines stay crisp near and thin out smoothly at range rather than shimmering.
	float aa = max(fwidth(across),0.002);
	float dash_aa = max(fwidth(UV.y)/8.0,0.002);
	float dash = smoothstep(0.0,dash_aa,fract(UV.y/8.0))*(1.0-smoothstep(0.42,0.42+dash_aa,fract(UV.y/8.0)));
	float centre_line = (1.0-smoothstep(0.06,0.06+aa,abs(across)))*dash*COLOR.g;
	float edge_line = (1.0-smoothstep(0.05,0.05+aa,abs(side-(half_width-0.32))))*COLOR.b;
	float paint = max(centre_line,edge_line)*mix(0.45,0.85,blotch)*(1.0-smoothstep(120.0,300.0,view_dist));
	col = mix(col,vec3(0.74,0.72,0.64),paint);

	ALBEDO = col;
	float near = (1.0-smoothstep(25.0,110.0,view_dist))*COLOR.r;
	NORMAL_MAP = texture(asphalt_normal,p*0.24).rgb;
	NORMAL_MAP_DEPTH = 0.55*near;
	ROUGHNESS = mix(0.97,0.88,COLOR.r);
	SPECULAR = 0.25;
	ALPHA = (1.0-smoothstep(-0.25,0.8,edge))*COLOR.a*(1.0-smoothstep(fade_begin,fade_end,view_dist));
}
