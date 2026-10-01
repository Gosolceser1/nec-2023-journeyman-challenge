class_name TouchScroll
extends Node
## Finger drag-to-scroll for every ScrollContainer under `root`.
##
## project.godot keeps emulate_mouse_from_touch off (a finger arrives only as
## ScreenTouch / ScreenDrag, which the answer cards track with a slop check).
## Godot 4.7's ScrollContainer drags only on InputEventMouseButton/MouseMotion,
## so without this nothing scrolls under a finger. This runs in _input, before
## the GUI: a drag past DRAG_THRESHOLD claims the gesture for the scroller under
## the finger (whatever its children's mouse_filter), sends it
## NOTIFICATION_SCROLL_BEGIN (buttons drop their press, answer cards cancel) and
## swallows the rest of the gesture, release included, so a swipe never presses
## or answers anything. A tap that stays under the threshold is left alone.

## Canvas px a finger must travel before the gesture is a scroll. Below the
## answer card's TOUCH_SLOP_PX, so the scroller always cancels the card first.
const DRAG_THRESHOLD := 14.0
## Fling: release speed (px/s) that keeps the list gliding, and its decay rate.
const FLING_MIN_SPEED := 220.0
const FLING_FRICTION := 4.0
const FLING_STOP_SPEED := 30.0
## Only the most recent part of the drag sets the fling speed.
const VELOCITY_WINDOW_MSEC := 90

var root: Control

var _index := -1
var _press_pos := Vector2.ZERO
var _hit: Control
var _scroll: ScrollContainer
var _vertical := true
var _dragging := false
var _from := 0.0
var _samples: Array = []  # [msec, position along the axis]
var _fling_speed := 0.0
var _fling_scroll: ScrollContainer
var _fling_vertical := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(root):
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch(ev: InputEventScreenTouch) -> void:
	if ev.pressed:
		if _index >= 0:
			return
		var caught_fling := _fling_speed != 0.0
		_stop_fling()
		_index = ev.index
		_press_pos = ev.position
		_hit = find_control_at(root, ev.position)
		_scroll = null
		_dragging = false
		_samples.clear()
		if caught_fling:
			# A finger that stops a gliding list only stops it, like Android.
			_dragging = true
			_scroll = _scroll_for(_hit, true)
			if _scroll == null:
				_scroll = _scroll_for(_hit, false)
			if _scroll != null:
				_vertical = _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
				_from = _value(_scroll, _vertical)
				_samples.append([Time.get_ticks_msec(), _axis(ev.position)])
				get_viewport().set_input_as_handled()
			else:
				_dragging = false
		return
	if ev.index != _index:
		return
	var was_dragging := _dragging
	var scroll := _scroll
	_index = -1
	_dragging = false
	_scroll = null
	_hit = null
	if was_dragging:
		get_viewport().set_input_as_handled()
		if is_instance_valid(scroll):
			_start_fling(scroll)
			scroll.scroll_ended.emit()


func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index != _index:
		return
	if not _dragging:
		var moved: Vector2 = ev.position - _press_pos
		if moved.length() < DRAG_THRESHOLD:
			return
		var vertical := absf(moved.y) >= absf(moved.x)
		var scroll := _scroll_for(_hit, vertical)
		if scroll == null:
			return  # nothing here scrolls that way: leave the gesture to the GUI
		_scroll = scroll
		_vertical = vertical
		_dragging = true
		_from = _value(scroll, vertical)
		_press_pos = ev.position
		_samples.clear()
		scroll.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		scroll.scroll_started.emit()
	if not is_instance_valid(_scroll):
		return
	get_viewport().set_input_as_handled()
	var along := _axis(ev.position)
	var start := _axis(_press_pos)
	_set_value(_scroll, _vertical, _from - (along - start))
	var now := Time.get_ticks_msec()
	_samples.append([now, along])
	while _samples.size() > 2 and now - int(_samples[0][0]) > VELOCITY_WINDOW_MSEC:
		_samples.pop_front()


func _axis(pos: Vector2) -> float:
	return pos.y if _vertical else pos.x


func _start_fling(scroll: ScrollContainer) -> void:
	if _samples.size() < 2:
		return
	var first: Array = _samples[0]
	var last: Array = _samples[-1]
	var dt := float(int(last[0]) - int(first[0])) / 1000.0
	if dt <= 0.0:
		return
	var speed := -(float(last[1]) - float(first[1])) / dt
	if absf(speed) < FLING_MIN_SPEED:
		return
	_fling_speed = speed
	_fling_scroll = scroll
	_fling_vertical = _vertical
	set_process(true)


func _stop_fling() -> void:
	_fling_speed = 0.0
	_fling_scroll = null
	set_process(false)


func _process(delta: float) -> void:
	if not is_instance_valid(_fling_scroll) or not _fling_scroll.is_visible_in_tree():
		_stop_fling()
		return
	var before := _value(_fling_scroll, _fling_vertical)
	_set_value(_fling_scroll, _fling_vertical, before + _fling_speed * delta)
	_fling_speed *= exp(-FLING_FRICTION * delta)
	if absf(_fling_speed) < FLING_STOP_SPEED or is_equal_approx(before, _value(_fling_scroll, _fling_vertical)):
		_stop_fling()


static func _value(scroll: ScrollContainer, vertical: bool) -> float:
	return (scroll.get_v_scroll_bar() if vertical else scroll.get_h_scroll_bar()).value


static func _set_value(scroll: ScrollContainer, vertical: bool, value: float) -> void:
	var bar: ScrollBar = scroll.get_v_scroll_bar() if vertical else scroll.get_h_scroll_bar()
	bar.value = clampf(value, bar.min_value, maxf(bar.min_value, bar.max_value - bar.page))


## Whether `scroll` has somewhere to go on that axis.
static func can_scroll(scroll: ScrollContainer, vertical: bool) -> bool:
	if not scroll.is_visible_in_tree():
		return false
	var mode := scroll.vertical_scroll_mode if vertical else scroll.horizontal_scroll_mode
	if mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var bar: ScrollBar = scroll.get_v_scroll_bar() if vertical else scroll.get_h_scroll_bar()
	return bar.max_value - bar.page > 0.5


## The innermost ScrollContainer above `hit` that can scroll on that axis. Stops
## at a CanvasLayer: an overlay (the figure zoom) never scrolls the page under it.
static func _scroll_for(hit: Node, vertical: bool) -> ScrollContainer:
	var n := hit
	while n != null:
		if n is CanvasLayer or n is Window:
			return null
		if n is ScrollContainer and can_scroll(n, vertical):
			return n
		n = n.get_parent()
	return null


## The control a finger at `pos` lands on, by the engine's rules: children in
## reverse tree order, CanvasLayers above the canvas by layer, hidden subtrees
## and clipped areas skipped, MOUSE_FILTER_IGNORE controls transparent.
static func find_control_at(from: Node, pos: Vector2) -> Control:
	var layers: Array = from.find_children("*", "CanvasLayer", true, false)
	layers.sort_custom(func(a: CanvasLayer, b: CanvasLayer) -> bool: return a.layer > b.layer)
	for layer in layers:
		if layer.visible and layer.layer > 0:
			var hit := _find_in(layer, pos)
			if hit != null:
				return hit
	return _find_in(from, pos)


static func _find_in(node: Node, pos: Vector2) -> Control:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return null
	if node is CanvasLayer and not (node as CanvasLayer).visible:
		return null
	var control := node as Control
	if control != null and control.clip_contents and not control.get_global_rect().has_point(pos):
		return null
	for i in range(node.get_child_count() - 1, -1, -1):
		var child := node.get_child(i)
		if child is CanvasLayer or child is Window:
			continue  # handled by find_control_at, or its own viewport
		var hit := _find_in(child, pos)
		if hit != null:
			return hit
	if control != null and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(pos):
		return control
	return null
