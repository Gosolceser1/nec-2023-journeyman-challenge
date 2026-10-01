shader_type canvas_item;

// Label glyph shader: a cyan energy band sweeps across the text, with a rare
// brief flicker like an arcing sign. Works on the glyph alpha only.
uniform float text_width = 400.0;
// Where this label starts inside a wider swept row (UiFx.electrify_title span).
uniform float x_offset = 0.0;
uniform vec4 band_color : source_color = vec4(0.49, 0.83, 0.99, 1.0);
uniform float period = 3.6;

varying vec2 local_pos;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 base = COLOR * texture(TEXTURE, UV);
	float t = mod(TIME, period) / period;
	float x = (local_pos.x + x_offset) / max(text_width, 1.0);
	float band = 1.0 - smoothstep(0.0, 0.09, abs(x - (t * 1.6 - 0.3)));
	vec3 rgb = mix(base.rgb, band_color.rgb, band * 0.85);
	float slot = floor(TIME * 12.0);
	float flicker = hash(slot) > 0.985 ? 0.55 : 1.0;
	COLOR = vec4(rgb, base.a * flicker);
}
