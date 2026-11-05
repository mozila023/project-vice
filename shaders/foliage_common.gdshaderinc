// Atlas cut-out colour shared by near and far plant cards.
uniform sampler2D atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float grid = 2.0;
varying vec2 cell_uv;
varying float tone;
varying float fade;

float dither(vec2 frag) {
	return fract(52.9829189*fract(dot(frag,vec2(0.06711056,0.00583715))));
}

// Olive source leaves toward wet-tropics green, each plant a little different. Bark is left alone.
vec3 foliage_colour(vec3 source,float t) {
	float green = smoothstep(-0.03,0.05,source.g-source.r);
	return mix(source,source*mix(vec3(0.60,0.92,0.46),vec3(0.82,1.05,0.52),t),green);
}
