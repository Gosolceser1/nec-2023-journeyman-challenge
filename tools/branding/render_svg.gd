extends SceneTree
## Renders SVGs to PNGs with Godot's own rasteriser (ThorVG), so no SVG
## library is needed. Driven by tools/branding/build_branding.py.
##   Godot --headless --path . --script tools/branding/render_svg.gd -- \
##       <in.svg> <out_prefix> <size,size,...> [<in.svg> <out_prefix> <sizes> ...]
## Writes <out_prefix>_<size>.png for each size. Each SVG must be square.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args.size() % 3 != 0:
		push_error("usage: -- <in.svg> <out_prefix> <sizes> [...]")
		quit(2)
		return
	for i in range(0, args.size(), 3):
		if not _render(args[i], args[i + 1], args[i + 2]):
			quit(1)
			return
	quit(0)


func _render(svg_path: String, prefix: String, sizes: String) -> bool:
	var text := FileAccess.get_file_as_string(svg_path)
	var probe := Image.new()
	if text.is_empty() or probe.load_svg_from_string(text, 1.0) != OK:
		push_error("cannot parse " + svg_path)
		return false
	var base := float(probe.get_width())
	for part in sizes.split(","):
		var size := int(part)
		var img := Image.new()
		img.load_svg_from_string(text, size / base)
		if img.get_width() != size or img.get_height() != size:
			img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		if img.save_png("%s_%d.png" % [prefix, size]) != OK:
			push_error("cannot write %s_%d.png" % [prefix, size])
			return false
	return true
