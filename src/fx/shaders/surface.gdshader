shader_type canvas_item;

// One material for every raised surface (UiFx.add_glass / UiFx.add_shine).
// It only touches the control's own drawing (its StyleBox, and a Button's
// label), never child controls, and every effect is off at its default.
//
// Glass: inside the rounded rect the fill is lifted by fill_lift at the top
// edge, fading to the StyleBox colour at the bottom (a vertical gradient),
// and a 1 px highlight runs just under the top border (bevel).
//
// Tint: the fill blends toward tint_to across the width (the primary button's
// cyan -> deep blue bar). Pure-white fragments are the button's label and are
// left alone, so the text keeps its contrast.
//
// Shine: a diagonal light sweep; shine_pos runs -0.3 -> 1.5 (tweened).
//
// Current: one pulse of light runs around the border; current_pos runs
// 0 -> 1 + current_tail (tweened), below 0 it is off.
//
// Flow: a slow, endless light on the border (the official simulator card),
// flow_strength 0 = off. Runs on TIME, so it costs no CPU.
uniform vec2 rect_size = vec2(400.0, 60.0);
uniform float corner_radius = 12.0;
uniform vec3 fill_lift = vec3(0.0);
uniform float bevel = 0.0;
uniform vec4 tint_to : source_color = vec4(0.0);
uniform float tint_amount = 0.0;
uniform float shine_pos = -1.0;
uniform float shine_width = 0.12;
uniform float strength = 0.14;
uniform float current_pos = -1.0;
uniform float current_tail = 0.22;
uniform float current_strength = 1.0;
uniform vec4 current_color : source_color = vec4(0.49, 0.83, 0.99, 1.0);
uniform float flow_strength = 0.0;
uniform float flow_speed = 0.08;
uniform vec4 flow_color : source_color = vec4(0.98, 0.75, 0.14, 1.0);

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

// Brightness of a light head at `pos` (0..1 around the outline) with a tail.
float head_at(float pos, float t, float tail) {
	float behind = pos - t;
	behind = behind < 0.0 ? behind + 1.0 : behind;
	return behind <= tail ? 1.0 - behind / tail : 0.0;
}

void fragment() {
	vec4 base = COLOR * texture(TEXTURE, UV);
	vec2 size = max(rect_size, vec2(1.0));
	vec2 p = local_pos / size;
	vec2 b = size * 0.5;
	vec2 q = local_pos - b;
	vec2 k = abs(q) - b + vec2(corner_radius);
	float sdf = length(max(k, vec2(0.0))) + min(max(k.x, k.y), 0.0) - corner_radius;
	bool is_label = min(base.r, min(base.g, base.b)) > 0.97;
	if (sdf <= 0.0 && !is_label) {
		base.rgb += fill_lift * (1.0 - clamp(p.y, 0.0, 1.0));
		base.rgb = mix(base.rgb, tint_to.rgb, tint_amount * clamp(p.x, 0.0, 1.0));
		if (bevel > 0.0) {
			float band = 1.0 - smoothstep(0.0, 1.0, abs(local_pos.y - 1.5));
			float ends = smoothstep(0.0, corner_radius, min(local_pos.x, size.x - local_pos.x));
			base.rgb += vec3(bevel * band * ends);
		}
	}
	float d = abs((p.x + p.y * 0.35) - shine_pos);
	base.rgb += vec3((1.0 - smoothstep(0.0, shine_width, d)) * strength);
	float edge = 1.0 - smoothstep(0.0, 4.0, abs(sdf + 1.0));
	if (current_pos >= 0.0) {
		float along = perimeter_t(q, b);
		float behind = current_pos - along;
		behind = behind < 0.0 ? behind + 1.0 : behind;
		float head = behind <= current_tail && current_pos - behind >= -0.001 ? 1.0 - behind / current_tail : 0.0;
		float glow = head * head * edge * current_strength;
		base.rgb += current_color.rgb * glow;
		base.a = max(base.a, glow * 0.85);
	}
	if (flow_strength > 0.0) {
		float along = perimeter_t(q, b);
		float t = fract(TIME * flow_speed);
		float h = head_at(t, along, 0.18) + head_at(fract(t + 0.5), along, 0.18);
		float glow = h * h * edge * flow_strength;
		base.rgb += flow_color.rgb * glow;
		base.a = max(base.a, glow * 0.7);
	}
	COLOR = base;
}
