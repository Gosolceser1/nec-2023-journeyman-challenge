extends SceneTree
# THROWAWAY: clean per-record measurement (fresh node per record). Delete when done.
#   Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tools/_tmp_layout_audit.gd -- --mobile-ui

const SIDE := 16.0

func _init() -> void:
	for id in ["final-exam-#1-013", "final-exam-#1-014", "final-exam-#1-026", "final-exam-#3-048", "final-exam-#1-004", "final-exam-#3-065"]:
		await _fresh(id)
	quit(0)

func _fresh(id: String) -> void:
	var mob = load("res://Main.tscn").instantiate()
	root.add_child(mob)              # _ready() runs here; --mobile-ui makes it build mobile
	await process_frame
	root.size = Vector2i(540, 1200)  # now emulate the Pixel 7 visible rect
	await process_frame
	await process_frame
	var all: Array[int] = []
	for i in mob.records.size():
		all.append(i)
	mob.order = all
	mob.session_length = mob.records.size()
	mob.main_margin.add_theme_constant_override("margin_left", int(SIDE))
	mob.main_margin.add_theme_constant_override("margin_right", int(SIDE))
	mob.main_margin.add_theme_constant_override("margin_top", 41)
	mob.main_margin.add_theme_constant_override("margin_bottom", 45)
	var idx := -1
	for i in mob.records.size():
		if str(mob.records[i].get("id", "")) == id:
			idx = i
	if idx < 0:
		mob.queue_free(); return
	mob.menu_overlay.visible = false
	mob.current_index = idx
	mob._show_question()
	await process_frame
	await process_frame

	var vw := 540.0
	var avail := vw - SIDE * 2.0
	var qsc: ScrollContainer = _ancestor_scroll(mob.question_panel)
	var gr: Rect2 = qsc.get_global_rect()
	print("\n=== %s   visible=%.0fx%.0f  available=%.0f ===" % [id, vw, root.get_visible_rect().size.y, avail])
	print("  quiz_scroll size.x=%.1f MIN.x=%.1f global=[%.0f..%.0f] h_mode=%d(DISABLED=%d) clip=%s" % [
		qsc.size.x, qsc.get_combined_minimum_size().x, gr.position.x, gr.end.x,
		qsc.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, str(qsc.clip_contents)])
	var mmx: float = qsc.get_combined_minimum_size().x
	if mmx > avail + 0.5:
		print("  >>> H-OVERFLOW: quiz column needs %.0fpx, only %.0fpx exist (+%.0f). h_mode=DISABLED + clip_contents -> CUT OFF, unreachable" % [mmx, avail, mmx - avail])
	if mob.question_diagram_panel.visible:
		print("  diagram: AUTOWRAP_OFF label min.x=%.1f  diagram_panel min.x=%.1f  (panel starts at x=%.0f, so its right edge is %.0f vs screen 540)" % [
			mob.question_diagram_label.get_combined_minimum_size().x,
			mob.question_diagram_panel.get_combined_minimum_size().x,
			mob.question_diagram_panel.get_global_rect().position.x,
			mob.question_diagram_panel.get_global_rect().end.x])
	if mob.question_table_panel.visible:
		var ts: ScrollContainer = mob.question_table_scroll
		var g: Control = mob.question_table_grid
		var rows := int(g.get_child_count() / maxi(g.columns, 1))
		var gmin := g.get_combined_minimum_size()
		print("  table: cols=%d rows=%d grid.min=%.0fx%.0f  actual_row_pitch=%.1f" % [
			g.columns, rows, gmin.x, gmin.y, gmin.y / float(maxi(rows, 1))])
		print("  table: scrollbox.size=%.0fx%.0f asked_min=%.0fx%.0f h_mode=%d h_bar.max=%.0f" % [
			ts.size.x, ts.size.y, ts.custom_minimum_size.x, ts.custom_minimum_size.y,
			ts.horizontal_scroll_mode, ts.get_h_scroll_bar().max_value])
		print("  table: panel asked_y=%.0f real_min_y=%.0f real_size_y=%.0f" % [
			mob.question_table_panel.custom_minimum_size.y,
			mob.question_table_panel.get_combined_minimum_size().y,
			mob.question_table_panel.size.y])
		if gmin.x > ts.size.x + 0.5:
			print("  >>> TABLE H-OVERFLOW: grid %.0f > scrollbox %.0f = %.0fpx hidden (%.0f%%); h_mode=AUTO so sideways scroll required" % [
				gmin.x, ts.size.x, gmin.x - ts.size.x, 100.0 * (gmin.x - ts.size.x) / gmin.x])
		# does the grid actually scroll back?
		ts.get_h_scroll_bar().value = ts.get_h_scroll_bar().max_value
		await process_frame
		print("  after setting h_bar.value=max, grid global x=[%.0f..%.0f] (right edge vs scrollbox right=%.0f)" % [
			g.get_global_rect().position.x, g.get_global_rect().end.x, ts.get_global_rect().end.x])
	# vertical: does the fixed dock + next_button leave the quiz room to breathe?
	print("  VERTICAL: root VBox children:")
	var rv: Control = mob.main_margin.get_child(0)
	for ch in rv.get_children():
		var c: Control = ch
		if not c.is_visible_in_tree():
			continue
		print("     %-14s size=%s min=%s" % [c.get_class(), str(c.size), str(c.get_combined_minimum_size())])
	print("     main_margin.size.y=%.0f  root VBox min.y=%.0f" % [mob.main_margin.size.y, rv.get_combined_minimum_size().y])
	mob.queue_free()
	await process_frame

func _ancestor_scroll(n: Control) -> ScrollContainer:
	var p: Node = n.get_parent()
	while p != null:
		if p is ScrollContainer:
			return p as ScrollContainer
		p = p.get_parent()
	return null
