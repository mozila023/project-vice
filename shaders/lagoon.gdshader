shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_always, shadows_disabled;
// Sea surface. Depth comes from the baked elevation map, so it needs no depth-buffer read
// and behaves the same on WebGL2 and phones.
uniform sampler2D data_map : filter_linear, repeat_disable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float detail = 1.0;
uniform float sun_strength = 1.0;
uniform float night = 0.0;
varying vec3 world_pos;

float elevation(vec2 p) {
	vec2 uv = p/2880.0+0.5;
	if (uv.x<0.0 || uv.y<0.0 || uv.x>1.0 || uv.y>1.0) return -33.0;
	float r = texture(data_map,uv).r;
	if (r>=0.5) return (r-0.5)*16.0;
	float s = (0.5-r)*2.0;
	return -33.0*s*s;
}

void vertex() {
	world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float dist = length(world_pos-CAMERA_POSITION_WORLD);
	float fade = 1.0-smoothstep(60.0,420.0,dist);
	float swell = sin(world_pos.x*0.11+TIME*0.9)*0.5+sin(world_pos.z*0.07-world_pos.x*0.04+TIME*0.6)*0.5;
	VERTEX.y += swell*0.05*fade;
	world_pos.y = VERTEX.y;
}

void fragment() {
	vec2 p = world_pos.xz;
	float dist = length(world_pos-CAMERA_POSITION_WORLD);
	float depth = max(-elevation(p),0.0);
	vec2 flow = vec2(0.012,0.008);

	// Three scales of wave: chop near the camera, rolling swell mid-range, broad wind streaks far.
	vec3 n1 = texture(normal_tex,p*0.055+TIME*flow*1.7).rgb;
	vec3 n2 = texture(normal_tex,p*0.021-TIME*flow.yx*1.1+0.31).rgb;
	vec3 n3 = texture(normal_tex,p*0.0035+TIME*flow*0.25).rgb;
	vec2 wave = (n1.xy-0.5)*mix(0.25,1.0,detail)*(1.0-smoothstep(150.0,700.0,dist));
	wave += (n2.xy-0.5)*1.0*(1.0-smoothstep(600.0,2500.0,dist)*0.6);
	wave += (n3.xy-0.5)*0.7;
	// Sheltered shallows lie flatter than open water.
	wave *= mix(0.42,1.0,smoothstep(0.2,6.0,depth));
	NORMAL_MAP = vec3(wave*0.5+0.5,1.0);
	NORMAL_MAP_DEPTH = 0.55;

	// Colour by water column: clear turquoise over sand, through teal, to deep ocean blue.
	// Water itself reflects little: these are deliberately dark, sky reflection adds the rest.
	vec3 shallow = vec3(0.045,0.36,0.34);
	vec3 mid = vec3(0.006,0.15,0.22);
	vec3 deep = vec3(0.002,0.022,0.075);
	vec3 water = mix(shallow,mid,smoothstep(0.5,5.0,depth));
	water = mix(water,deep,smoothstep(4.0,24.0,depth));

	// Breaking foam: pulses running up the beach.
	vec4 fn = texture(noise_tex,p*0.05+TIME*vec2(0.006,-0.004));
	vec4 fn2 = texture(noise_tex,p*0.33-TIME*vec2(0.01,0.007));
	float lace = smoothstep(0.24,0.8,fn2.g*0.6+fn.r*0.55);
	float run = sin(depth*11.0-TIME*0.9+fn.r*9.0)*0.5+0.5;
	float shore = (1.0-smoothstep(0.02,0.24,depth))*(0.25+run*0.75)*lace;
	float foam = clamp(shore,0.0,1.0)*(1.0-smoothstep(500.0,1400.0,dist)*0.8);

	float view_fresnel = pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),4.0);
	ALBEDO = mix(water*mix(1.0,0.5,night),vec3(0.93,0.96,0.95)*mix(1.0,0.3,night),foam);
	EMISSION = vec3(0.004,0.012,0.028)*night;
	ROUGHNESS = mix(0.075,0.72,foam);
	SPECULAR = 0.34;
	METALLIC = 0.0;
	// Clear at the waterline so the seabed shows; opaque with depth and at grazing angles.
	float clarity = 1.0-exp(-depth*0.62);
	ALPHA = clamp(max(mix(0.16,1.0,clarity),view_fresnel*0.9)+foam*0.75,0.0,1.0);
	ALPHA *= smoothstep(0.0,0.05,depth+0.02);
}



