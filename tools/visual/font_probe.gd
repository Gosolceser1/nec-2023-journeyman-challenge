extends SceneTree
## Which font file each UI font name resolves to on this OS, and how wide a
## typical line is in it. The macOS CI job runs it to show what a Mac draws
## the UI with; on Windows it shows how much wider Arial (the stand-in for
## NEC_UI_FONT layout checks) is than Segoe UI.
##   Godot --headless --path . --script tools/visual/font_probe.gd

const SAMPLE := "Which conductor size is required for a 60-ampere branch circuit?"
const SIZE := 22


func _width(names: PackedStringArray, weight: int) -> float:
	var font := SystemFont.new()
	font.font_names = names
	font.font_weight = weight
	return font.get_string_size(SAMPLE, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x


func _initialize() -> void:
	var names := AppTheme.ui_font_names()
	print("FONTS os=%s list=%s" % [OS.get_name(), str(names)])
	var probe := names.duplicate()
	for extra in ["Helvetica Neue", "Arial", "Segoe UI"]:
		if not probe.has(extra):
			probe.append(extra)
	for n in probe:
		var path := OS.get_system_font_path(n, 500)
		var bold := OS.get_system_font_path(n, 700)
		var w := _width(PackedStringArray([n]), 500) if path != "" else 0.0
		print("  %-20s regular=%s  bold=%s  width=%.0f" % [n, path if path != "" else "-", bold if bold != "" else "-", w])
	for weight in [500, 700]:
		var ui := AppTheme.ui_font(weight)
		print("  ui_font(%d) -> %s %s  width=%.0f" % [weight, ui.get_font_name(), ui.get_font_style_name(), _width(names, weight)])
	quit()
