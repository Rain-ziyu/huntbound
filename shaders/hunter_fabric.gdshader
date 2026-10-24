shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.3,0.36,0.27,1.0);
uniform float wetness : hint_range(0.0,1.0) = 0.2;
uniform float pattern_seed = 0.0;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float fabric_noise(vec2 p) {
    vec2 cell=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash21(cell),hash21(cell+vec2(1.0,0.0)),f.x),mix(hash21(cell+vec2(0.0,1.0)),hash21(cell+vec2(1.0)),f.x),f.y);
}
void fragment() {
    vec2 yarn = UV*vec2(90.0,120.0);
    float detail = 1.0-smoothstep(0.25,0.85,max(fwidth(yarn.x),fwidth(yarn.y)));
    float weave = sin(yarn.x*6.283185)*sin(yarn.y*6.283185)*detail;
    float damp = fabric_noise(UV*6.0+vec2(pattern_seed));
    float edge = min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
    float seam = 1.0-smoothstep(0.005,0.018,edge);
    float stitch = (1.0-smoothstep(0.018,0.028,edge))*step(0.45,fract((UV.x+UV.y)*70.0));
    float shade = (0.97+0.06*(damp-0.5)+0.035*weave)*(1.0-wetness*0.08)*(1.0-seam*0.18)+stitch*0.045;
    ALBEDO = base_color.rgb*shade;
    ROUGHNESS = clamp(0.92-wetness*0.16+weave*0.025,0.74,0.97);
    SPECULAR = 0.22;
}
