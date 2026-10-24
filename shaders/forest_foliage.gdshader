shader_type spatial;
render_mode cull_disabled;
void vertex() {
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float breeze=sin(TIME*1.25+world.x*0.21+world.z*0.18)*0.045;
	VERTEX.x+=breeze*COLOR.a;
}
void fragment() {
	float vein=1.0-smoothstep(0.0,0.045,abs(UV.x-0.5));
	ALBEDO=COLOR.rgb*(0.88+UV.y*0.12)+vec3(0.025,0.035,0.008)*vein;
	ROUGHNESS=0.61;
}
