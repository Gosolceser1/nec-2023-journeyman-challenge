shader_type canvas_item;

// Faint circuit-board traces with current pulses running along some of them.
// rect_size must track the node's size (canvas units) so cells stay square.
// drift slides the whole board (px per second) for a slow parallax behind
// the panels; motion 0 (Reduce motion) freezes both the drift and the pulses.
uniform vec2 rect_size = vec2(540.0, 960.0);
uniform float cell = 46.0;
uniform vec4 trace_color : source_color = vec4(0.22, 0.74, 0.97, 0.06);
uniform vec4 pad_color : source_color = vec4(0.22, 0.74, 0.97, 0.10);
uniform vec4 pulse_color : source_color = vec4(0.49, 0.83, 0.99, 0.55);
uniform float speed = 0.12;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec2 drift = vec2(0.0);
uniform float motion : hint_range(0.0, 1.0) = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float line_mask(float d, float half_w) {
	return 1.0 - smoothstep(half_w, half_w + 1.0, d);
}

// Pulse head moving along 0..1 with a fading tail behind it.
float pulse_at(float pos, float seed) {
	float t = fract(TIME * motion * speed * (0.6 + seed) + seed * 7.0);
	float behind = t - pos;
	if (behind < 0.0) {
		behind += 1.0;
	}
	return pow(clamp(1.0 - behind / 0.10, 0.0, 1.0), 3.0);
}

void fragment() {
	vec2 px = UV * rect_size + TIME * motion * drift;
	vec2 id = floor(px / cell);
	vec2 local = px - id * cell;
	float h_row = hash(id);
	float h_col = hash(id + vec2(17.3, 5.1));

	float trace = 0.0;
	float pulse = 0.0;
	bool has_h = h_row > 0.42;
	bool has_v = h_col > 0.62;

	if (has_h) {
		float m = line_mask(abs(local.y - cell * 0.5), 0.6);
		trace = max(trace, m);
		float seed = hash(vec2(id.y, 3.7));
		if (seed > 0.55) {
			pulse = max(pulse, m * pulse_at(fract(px.x / rect_size.x), seed));
		}
	}
	if (has_v) {
		float m = line_mask(abs(local.x - cell * 0.5), 0.6);
		trace = max(trace, m);
		float seed = hash(vec2(id.x, 9.2));
		if (seed > 0.7) {
			pulse = max(pulse, m * pulse_at(fract(px.y / rect_size.y), seed));
		}
	}

	float pad = 0.0;
	if (has_h && has_v) {
		float r = length(local - vec2(cell * 0.5));
		pad = 1.0 - smoothstep(2.6, 3.8, r);
	}

	float a_trace = trace * trace_color.a;
	float a_pad = pad * pad_color.a;
	float a_pulse = pulse * pulse_color.a;
	float a = max(max(a_trace, a_pad), a_pulse) * intensity;
	vec3 rgb = trace_color.rgb;
	if (a_pulse > a_trace) {
		rgb = pulse_color.rgb;
	}
	COLOR = vec4(rgb, a);
}
