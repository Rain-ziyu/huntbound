shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;
uniform vec4 mist_color : source_color = vec4(0.58,0.72,0.48,0.50);
uniform float density : hint_range(0.0,1.0) = 1.0;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(cell),hash(cell+vec2(1.0,0.0)),f.x),mix(hash(cell+vec2(0.0,1.0)),hash(cell+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 flow = world_position.xz*1.4+vec2(TIME*0.12,-TIME*0.09);
	float cloud = (noise(flow)+0.45*noise(flow*2.1+world_position.y))/1.45;
	float edge = pow(clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),1.6);
	ALBEDO = mist_color.rgb;
	ALPHA = mist_color.a*density*edge*smoothstep(0.12,0.85,cloud);
}
