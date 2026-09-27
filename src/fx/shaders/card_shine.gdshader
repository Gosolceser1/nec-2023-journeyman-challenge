shader_type canvas_item;

// Diagonal light sweep across a control. shine_pos runs -0.3 -> 1.3 (driven by a
// tween); outside that range the control draws untouched.
uniform vec2 rect_size = vec2(400.0, 60.0);
uniform float shine_pos = -1.0;
uniform float shine_width = 0.12;
uniform float strength = 0.22;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 base = COLOR * texture(TEXTURE, UV);
	vec2 p = local_pos / max(rect_size, vec2(1.0));
	float d = abs((p.x + p.y * 0.35) - shine_pos);
	float s = 1.0 - smoothstep(0.0, shine_width, d);
	base.rgb += vec3(s * strength);
	COLOR = base;
}
