shader_type canvas_item;
uniform float ambient_time = 0.0;
uniform float motion_amount = 1.0;
// A conservative code-authored mask calibrated to the 1672 x 941 runtime image.
// Cyan gating excludes rocks, foliage, boats and warm wooden objects inside it.
float water_color(vec3 c) {
	return smoothstep(0.07, 0.20, min(c.g, c.b) - c.r);
}
float region(vec2 p) {
	float top = smoothstep(128.0, 152.0, p.y) * (1.0-smoothstep(170.0, 185.0, p.y));
	float left = (1.0-smoothstep(240.0, 270.0, p.x)) * smoothstep(245.0, 275.0, p.y) * (1.0-smoothstep(360.0, 390.0, p.y));
	float right = smoothstep(1430.0, 1460.0, p.x) * smoothstep(275.0, 295.0, p.y) * (1.0-smoothstep(365.0, 390.0, p.y));
	// Keep the top platform and railings out of the distant-water band.
	top *= 1.0 - smoothstep(675.0, 700.0, p.x)*(1.0-smoothstep(955.0, 980.0, p.x));
	return max(top, max(left, right));
}
void fragment() {
	vec2 px = UV * vec2(1672.0,941.0);
	vec4 base = texture(TEXTURE, UV);
	float mask = region(px) * water_color(base.rgb);
	// Sample an inset neighbourhood: texture edges are never dragged across land.
	mask *= water_color(texture(TEXTURE, UV+vec2(0.003,0.0)).rgb);
	mask *= water_color(texture(TEXTURE, UV-vec2(0.003,0.0)).rgb);
	mask *= water_color(texture(TEXTURE, UV+vec2(0.0,0.004)).rgb);
	mask *= water_color(texture(TEXTURE, UV-vec2(0.0,0.004)).rgb);
	vec2 offset = vec2(sin(px.y*0.065+ambient_time*0.7),sin(px.x*0.035+ambient_time*0.53))*vec2(0.0008,0.00045);
	vec4 moved = texture(TEXTURE, UV+offset*mask*motion_amount);
	float glint = sin(px.x*0.04+px.y*0.14-ambient_time*0.8)*0.018;
	COLOR = vec4(mix(base.rgb,moved.rgb,mask*motion_amount)+vec3(glint*mask*motion_amount),base.a);
}
