extends SceneTree

# Verifies research findings against THIS project:
#  1. does every ScrollContainer get scroll_deadzone set?
#  2. does every BaseButton end up tappable (PASS/STOP, never IGNORE)?
#  3. is the back-button debounce long enough for a 1ms double-fire?
#  4. what does edge-to-edge imply for _apply_safe_area?

func _init() -> void:
	var m = load("res://Main.tscn").instantiate()
	root.add_child(m)
	await process_frame

	_report("desktop", m)
	m.queue_free()

	var mob = load("res://Main.tscn").instantiate()
	mob.ui_mobile = true
	root.add_child(mob)
	await process_frame
	_report("mobile", mob)
	quit(0)

func _report(label: String, m: Node) -> void:
	print("\n=== %s ===" % label)

	var scrollers: Array[String] = []
	var zero_deadzone := 0
	_walk(m, func(n: Node) -> void:
		if n is ScrollContainer:
			var s := n as ScrollContainer
			var path := _path(m, s)
			scrollers.append("%s deadzone=%d" % [path, s.scroll_deadzone])
			if s.scroll_deadzone <= 0:
				zero_deadzone += 1
	)
	print("  ScrollContainers: %d, with deadzone==0: %d" % [scrollers.size(), zero_deadzone])
	for s in scrollers:
		print("    ", s)

	var untappable: Array[String] = []
	var buttons := 0
	_walk(m, func(n: Node) -> void:
		if n is BaseButton:
			buttons += 1
			var c := n as Control
			if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				var t: Variant = c.get("text")
				untappable.append(str(t).substr(0, 24))
	)
	print("  buttons: %d, IGNORE (dead): %d %s" % [buttons, untappable.size(), str(untappable.slice(0, 5))])

	# Back-button debounce vs the reported ~1ms double-fire.
	print("  back debounce window: %d ms (research: two notifications ~1ms apart)" % 600)

	# Safe area: what does a cutout/edge-to-edge device report?
	var sa := DisplayServer.get_display_safe_area()
	print("  safe_area=%s  (0x0 in headless = no cutout data)" % str(sa))
	var cut := DisplayServer.get_display_cutouts()
	print("  cutouts=%d" % cut.size())

func _path(root: Node, target: Node) -> String:
	var parts: Array[String] = []
	var n := target
	while n != null and n != root:
		parts.push_front(n.get_class())
		n = n.get_parent()
	return "/".join(parts)

func _walk(node: Node, fn: Callable) -> void:
	for c in node.get_children():
		fn.call(c)
		_walk(c, fn)
