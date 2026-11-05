// Shared terrain surface. Define HIGH for normal mapping and anti-tiling (desktop / capable devices).
uniform sampler2D macro_map : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D data_map : filter_linear, repeat_disable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D sand_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D forest_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
#ifdef HIGH
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
#endif
uniform float sun_strength = 1.0;
varying vec3 world_pos;
varying vec3 terrain_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	terrain_normal = NORMAL;
	TANGENT = vec3(1.0,0.0,0.0);
	BINORMAL = vec3(0.0,0.0,1.0);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 map_uv = p/2880.0+0.5;
	vec3 macro = texture(macro_map,map_uv).rgb;
	vec4 data = texture(data_map,map_uv);
	float dist = length(world_pos-CAMERA_POSITION_WORLD);
	vec4 big_noise = texture(noise_tex,p*0.011);
	float h = world_pos.y;

	float rock_mix = smoothstep(0.20,0.42,1.0-terrain_normal.y)*smoothstep(1.0,5.0,h);
	float sand_mix = 1.0-smoothstep(1.7,3.0,h+big_noise.r*0.8-0.4);
	float forest_mix = smoothstep(0.25,0.7,data.g);
	float dirt_mix = smoothstep(0.1,0.8,data.b+(big_noise.r-0.5)*0.35);

	vec3 grass = texture(grass_tex,p*0.17).rgb;
	vec3 floor_col = texture(forest_tex,p*0.083).rgb;
	vec3 rock = texture(rock_tex,p*0.11).rgb;
	vec3 sand_photo = texture(sand_tex,p*0.27).rgb;
#ifdef HIGH
	// Each surface also sampled rotated and at a slower scale, blended by broad noise: the repeat pattern disappears.
	float tile_mix = smoothstep(0.32,0.68,big_noise.g);
	mat2 turn = mat2(vec2(0.8,0.6),vec2(-0.6,0.8));
	grass = mix(grass,texture(grass_tex,turn*p*0.13+0.21).rgb,tile_mix);
	grass = grass*0.6+texture(grass_tex,p.yx*0.037+0.37).rgb*0.4;
	floor_col = mix(floor_col,texture(forest_tex,turn*p*0.061+0.53).rgb,tile_mix);
	rock = mix(rock,texture(rock_tex,turn*p*0.073+0.17).rgb,tile_mix);
	sand_photo = mix(sand_photo,texture(sand_tex,turn*p*0.19+0.71).rgb,tile_mix);
#endif
	grass *= mix(vec3(0.42,0.56,0.31),vec3(0.56,0.64,0.36),big_noise.r);
	floor_col *= vec3(0.40,0.40,0.28);
	rock *= vec3(0.62,0.62,0.56);
	// Pale coral sand: the photo keeps its grain, the colour is pulled toward the local beach.
	vec3 sand = mix(sand_photo,vec3(0.71,0.66,0.53),0.48)*0.9;
	// Trodden earth stays a mid brown: the leaf-litter photo alone would make every verge look burnt.
	vec3 earth = mix(vec3(dot(floor_col,vec3(0.4)))*vec3(1.75,1.5,1.12),vec3(0.36,0.31,0.23),0.45);

	vec3 near = mix(grass,floor_col,forest_mix);
	near = mix(near,earth,dirt_mix);
	near = mix(near,rock,rock_mix);
	near = mix(near,sand,sand_mix);
	// Distant land reads as baked map; near ground takes broad variation from it too.
	float macro_lum = dot(macro,vec3(0.33));
	vec3 base = mix(near,macro*mix(0.92,1.08,big_noise.r),smoothstep(35.0,260.0,dist));

	// Damp sand with a slow tide line; submerged ground takes the seabed map.
	float tide = sin(TIME*0.35+big_noise.r*7.0)*0.09;
	float wet = 1.0-smoothstep(0.1+tide,1.05+tide,h);
	float under = 1.0-smoothstep(-0.25,0.05,h);
	base = mix(base,macro*0.62,under);
	base *= mix(1.0,0.60,wet*(1.0-under));

	// Sunlight rippling on the sea floor in the shallows.
	vec2 c1 = p*0.075+TIME*vec2(0.018,0.011);
	vec2 c2 = p*0.052-TIME*vec2(0.013,0.016);
	float caustic = texture(noise_tex,c1).g*texture(noise_tex,c2).g;
	base += vec3(0.75,0.92,0.82)*pow(caustic,1.4)*0.9*under*(1.0-smoothstep(0.0,4.0,-h))*sun_strength;

	// Slow-moving cloud shadow across the island.
	float cloud = texture(noise_tex,p*0.00042+TIME*vec2(0.0011,0.0005)).r;
	base *= mix(1.0,0.74,smoothstep(0.50,0.68,cloud)*sun_strength*(1.0-under));

	// Baked contact shadow around buildings, and the permanent shade beneath the forest canopy.
	base *= data.a*mix(1.0,0.78,forest_mix);

	ALBEDO = base;
#ifdef HIGH
	float near_fade = 1.0-smoothstep(40.0,140.0,dist);
	vec3 n = mix(texture(grass_normal,p*0.17).rgb,texture(rock_normal,p*0.11).rgb,rock_mix);
	NORMAL_MAP = mix(n,texture(sand_normal,p*0.27).rgb,sand_mix);
	NORMAL_MAP_DEPTH = 0.65*near_fade;
#endif
	ROUGHNESS = mix(0.96,0.38,wet);
	SPECULAR = mix(0.22,0.5,wet);
}


