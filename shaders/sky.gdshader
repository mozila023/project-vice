shader_type sky;
// Photographed cloudy sky graded through the day, with analytic sun, sunset band and stars.
uniform sampler2D panorama : filter_linear, repeat_enable;
uniform float day = 1.0;
uniform float dusk = 0.0;

float star_field(vec3 dir) {
	vec3 cell = floor(dir*520.0);
	float h = fract(sin(dot(cell,vec3(12.9898,78.233,37.719)))*43758.5453);
	return step(0.9988,h)*(0.35+fract(h*91.7));
}

void sky() {
	vec3 dir = EYEDIR;
	float below = clamp(-dir.y*6.0,0.0,1.0);
	vec2 uv = vec2(atan(dir.x,-dir.z)/TAU+0.5,acos(clamp(max(dir.y,0.003),-1.0,1.0))/PI);
	vec3 photo = min(texture(panorama,uv).rgb,vec3(3.2));
	float lum = dot(photo,vec3(0.3,0.59,0.11));
	// Natural daylight: soften the saturated photo blue toward a hazy tropical sky.
	vec3 base = mix(photo,vec3(lum),0.3)*1.05+vec3(0.05,0.07,0.09);

	vec3 sun_dir = LIGHT0_ENABLED ? LIGHT0_DIRECTION : vec3(0.0,1.0,0.0);
	float toward = clamp(dot(dir,sun_dir),0.0,1.0);
	float horizon = pow(1.0-clamp(dir.y,0.0,1.0),5.0);

	// Dusk: warm the band near the sun, darken the opposite sky, keep cloud shapes from the photo.
	vec3 dusk_col = mix(vec3(0.34,0.28,0.42)*(0.5+lum),vec3(1.5,0.62,0.26)*(0.55+lum*0.7),pow(toward,3.0)*0.85+horizon*0.35);
	vec3 col = mix(base,dusk_col,dusk*0.9);

	// Night: moonlit photo, deep blue, stars.
	vec3 night_col = vec3(0.012,0.02,0.045)+base*vec3(0.015,0.02,0.035);
	if (AT_CUBEMAP_PASS) night_col += vec3(0.05,0.08,0.15);
	else night_col += vec3(0.8,0.85,1.0)*star_field(dir)*smoothstep(0.02,0.25,dir.y)*(1.0-smoothstep(0.35,0.75,lum));
	col = mix(night_col,col,day);

	if (!AT_CUBEMAP_PASS && LIGHT0_ENABLED && day>0.02) {
		float angle = acos(clamp(dot(dir,sun_dir),-1.0,1.0));
		float disc = 1.0-smoothstep(0.012,0.02,angle);
		float glow = exp(-angle*7.0)*0.55+exp(-angle*38.0)*1.2;
		// Thick cloud hides the disc but not the glow behind it.
		float cover = 1.0-smoothstep(0.7,1.8,lum);
		col += vec3(1.0,0.86,0.62)*LIGHT0_COLOR*(disc*14.0*cover+glow*(0.55+dusk))*day;
	}
	// Soft haze at the horizon joins the sky to the sea; below it fades out.
	vec3 haze = mix(vec3(0.68,0.80,0.90)*1.05,vec3(0.93,0.62,0.42),dusk);
	haze = mix(vec3(0.02,0.032,0.06),haze,day);
	col = mix(col,haze,pow(1.0-clamp(dir.y*2.6,0.0,1.0),5.0)*0.75);
	// Ambient light picks up warm bounce from the ground below, so shaded walls are not blue-black.
	if (AT_CUBEMAP_PASS) {
		col = mix(col,col*vec3(0.72,0.82,0.92),pow(1.0-clamp(dir.y,0.0,1.0),3.0)*0.5);
		COLOR = mix(col,vec3(0.50,0.46,0.36)*mix(0.1,1.0,day),below);
	} else {
		COLOR = mix(col,haze*0.72,below);
	}
}



