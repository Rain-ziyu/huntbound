shader_type spatial;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float strata=sin(world_position.y*3.2+sin(world_position.x*0.65+world_position.z*0.48)*1.2)*0.5+0.5;
	float patch=sin(world_position.x*0.8+world_position.z*0.65)*sin(world_position.y*0.38)*0.5+0.5;
	vec3 rock=mix(vec3(0.18,0.20,0.18),vec3(0.30,0.32,0.28),strata*0.45);
	float moss=smoothstep(0.45,0.80,patch)*(1.0-smoothstep(5.0,15.0,world_position.y));
	ALBEDO=mix(rock,vec3(0.16,0.23,0.11),moss*0.8);
	ROUGHNESS=0.70;
}
