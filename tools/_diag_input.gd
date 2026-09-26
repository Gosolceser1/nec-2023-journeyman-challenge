extends SceneTree

var f := 0
var hit := 0
var inp := 0
var lines: Array = []

class Spy extends Control:
	var owner_ref
	var n := 0
	var seen: Array = []
	func _input(ev: InputEvent) -> void:
		n += 1
		seen.append("%s/%s" % [ev.type, "pressed" if (ev is InputEventKey and ev.pressed) else ""])
	func _gui_input(ev: InputEvent) -> void:
		seen.append("GUI:" + str(ev.type))

var spy: Spy

func _initialize() -> void:
	root.size = Vector2i(540, 960)
	var c := ColorRect.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(c)
	spy = Spy.new()
	spy.owner_ref = self
	spy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spy.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(spy)

func _process(_d: float) -> bool:
	f += 1
	match f:
		1:
			print("DIAG| root.size=", root.size, " root.gui_hover=", root.get_hovered_control())
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			ev.position = Vector2(100, 100)
			print("DIAG| push_input via root.push_input")
			root.push_input(ev)
		2:
			print("DIAG| after push_input hover=", root.get_hovered_control(), " spy.seen=", spy.seen)
			var ev := InputEventScreenTouch.new()
			ev.index = 0
			ev.pressed = true
			ev.position = Vector2(200, 200)
			print("DIAG| push_input via Input.parse_input_event")
			Input.parse_input_event(ev)
		3:
			print("DIAG| after parse_input_event spy.seen=", spy.seen, " hover=", root.get_hovered_control())
			print("DIAG| emu_mouse_from_touch=", ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"))
			print("DIAG| viewport gui_embed=", root.gui_embed_subwindows, " disable_input=", OS.has_feature("headless"))
			return true
	return false
