shader_type spatial;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float ripple=sin(world_position.z*11.0-TIME*1.8+sin(world_position.x*5.0))*0.5+0.5;
	float fine=sin(world_position.x*24.0+world_position.z*8.0+TIME)*0.5+0.5;
	ALBEDO=mix(vec3(0.10,0.20,0.18),vec3(0.26,0.37,0.30),ripple*0.25+fine*0.08);
	ROUGHNESS=0.13+ripple*0.09;
	SPECULAR=0.65;
	METALLIC=0.15;
}
