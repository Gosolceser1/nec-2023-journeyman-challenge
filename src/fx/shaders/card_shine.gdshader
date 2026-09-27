shader_type canvas_item;

// Diagonal light sweep across a control. shine_pos runs -0.3 -> 1.3 (driven by a
// tween); outside that range the control draws untouched.
//
// Energized border: a pulse of current runs once around the rounded outline.
// current_pos runs 0 -> 1 + current_tail (driven by a tween); below 0 it is off
// and the control draws untouched.
uniform vec2 rect_size = vec2(400.0, 60.0);
uniform float shine_pos = -1.0;
uniform float shine_width = 0.12;
uniform float strength = 0.22;
uniform float current_pos = -1.0;
uniform float current_tail = 0.22;
uniform float current_strength = 1.0;
uniform vec4 current_color : source_color = vec4(0.49, 0.83, 0.99, 1.0);
uniform float corner_radius = 14.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// 0..1 around the outline, clockwise from the top-left corner.
float perimeter_t(vec2 q, vec2 b) {
	float dx = b.x - abs(q.x);
	float dy = b.y - abs(q.y);
	float per = 4.0 * (b.x + b.y);
	float s;
	if (dy < dx) {
		s = q.y < 0.0 ? q.x + b.x : 2.0 * b.x + 2.0 * b.y + (b.x - q.x);
	} else {
		s = q.x > 0.0 ? 2.0 * b.x + (q.y + b.y) : 4.0 * b.x + 2.0 * b.y + (b.y - q.y);
	}
	return s / per;
}

void fragment() {
	vec4 base = COLOR * texture(TEXTURE, UV);
	vec2 p = local_pos / max(rect_size, vec2(1.0));
	float d = abs((p.x + p.y * 0.35) - shine_pos);
	float s = 1.0 - smoothstep(0.0, shine_width, d);
	base.rgb += vec3(s * strength);
	if (current_pos >= 0.0) {
		vec2 b = rect_size * 0.5;
		vec2 q = local_pos - b;
		vec2 k = abs(q) - b + vec2(corner_radius);
		float sdf = length(max(k, vec2(0.0))) + min(max(k.x, k.y), 0.0) - corner_radius;
		float band = 1.0 - smoothstep(0.0, 4.0, abs(sdf + 1.0));
		float behind = current_pos - perimeter_t(q, b);
		behind = behind < 0.0 ? behind + 1.0 : behind;
		float head = behind <= current_tail && current_pos - behind >= -0.001 ? 1.0 - behind / current_tail : 0.0;
		float glow = head * head * band * current_strength;
		base.rgb += current_color.rgb * glow;
		base.a = max(base.a, glow * 0.85);
	}
	COLOR = base;
}
