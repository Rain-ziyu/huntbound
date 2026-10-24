shader_type spatial;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float groove=pow(abs(sin(UV.x*120.0+sin(UV.y*8.0)*0.6)),0.6);
	float grain=hash(floor(UV*vec2(110.0,15.0)));
	vec3 brown=mix(vec3(0.09,0.075,0.052),vec3(0.25,0.23,0.16),groove*0.6+grain*0.4);
	float moss=(1.0-smoothstep(0.0,0.30,UV.y))*smoothstep(0.25,0.75,grain);
	ALBEDO=mix(brown,vec3(0.16,0.23,0.10),moss*0.65);
	ROUGHNESS=0.85;
}
