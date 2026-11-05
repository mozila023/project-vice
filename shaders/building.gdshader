shader_type spatial;
uniform vec4 paint : source_color = vec4(0.75,0.77,0.69,1.0);
uniform bool corrugated = false;
varying vec3 p;
float hash(vec2 v) {return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float grain=hash(floor(p.xz*55.0+p.y*7.0));
	float dirt=sin(p.x*2.1+sin(p.z*2.4))*sin(p.y*3.2)*0.035;
	float slat=smoothstep(0.92,1.0,fract(p.y*4.8));
	float rib=sin(p.x*42.0)*0.06;
	ALBEDO=paint.rgb*(0.90+grain*0.1+dirt-(corrugated?rib:slat*0.12));
	ROUGHNESS=corrugated?0.6:0.91;
	if(corrugated){NORMAL_MAP=normalize(vec3(sin(p.x*42.0)*0.25,0.0,1.0))*0.5+0.5;}
}
