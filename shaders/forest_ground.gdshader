shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz;
	float broad=noise(p*0.24);
	float grain=noise(p*18.0);
	float trail=1.0-smoothstep(3.2,6.8,abs(p.x));
	float bank=1.0-smoothstep(2.0,5.0,abs(p.x-41.0));
	float moss=smoothstep(0.28,0.76,broad)*(1.0-trail*0.8);
	vec3 dirt=mix(vec3(0.12,0.10,0.075),vec3(0.17,0.15,0.11),grain);
	vec3 green=mix(vec3(0.10,0.16,0.07),vec3(0.15,0.22,0.10),grain);
	float wet=smoothstep(0.60,0.75,noise(p*0.34+vec2(8.0,3.0)))*(0.45+0.55*trail);
	wet=max(wet,bank*0.85);
	ALBEDO=mix(mix(dirt,green,moss),vec3(0.075,0.11,0.095),wet*0.70);
	ROUGHNESS=mix(0.88,0.13,wet);
	SPECULAR=mix(0.25,0.75,wet);
}
