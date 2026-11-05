shader_type spatial;
render_mode blend_mix,cull_disabled,depth_draw_always;
uniform sampler2D normal_tex : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D noise_tex : filter_linear_mipmap,repeat_enable;
varying vec3 world_pos;
varying vec3 face_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;face_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float falling=1.0-smoothstep(.2,.8,abs(face_normal.y));
 vec2 p=mix(world_pos.xz*.18,vec2(world_pos.x*.3,world_pos.y*.7+TIME*.65),falling);
 vec3 n=texture(normal_tex,p+TIME*vec2(.01,.018)).rgb;
 float streak=texture(noise_tex,p*vec2(1.8,.3)+TIME*vec2(.015,.13)).g;
 ALBEDO=mix(vec3(.025,.23,.20),vec3(.80,.89,.86),falling*(.75+streak*.25));
 NORMAL_MAP=n;
 NORMAL_MAP_DEPTH=.24;
 ROUGHNESS=mix(.12,.4,falling);
 SPECULAR=.45;
 ALPHA=mix(.65,.8,falling)+streak*.12;
}
