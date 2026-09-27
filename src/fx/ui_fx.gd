class_name UiFx
extends RefCounted

## Visual effects shared by the desktop and mobile layouts: shader backdrops,
## particle bursts, flashes and glow pulses. Everything here is decoration —
## no quiz state lives in these nodes, and every spawned node frees itself.

const CIRCUIT_SHADER := preload("res://src/fx/shaders/circuit_backdrop.gdshader")
const TITLE_SHADER := preload("res://src/fx/shaders/electric_title.gdshader")
const SURFACE_SHADER := preload("res://src/fx/shaders/surface.gdshader")

const CYAN := AppTheme.SKY_400
const EMERALD := AppTheme.EMERALD_400
const RED := AppTheme.RED_400
const AMBER := AppTheme.AMBER_400

## Particle nodes alive on one fx layer are capped so rapid answering (or the
## headless harness answering hundreds of items without frames) can't pile up.
const MAX_LIVE_BURSTS := 8

## The circuit board sits well behind the panels: 40% of its old strength,
## pulses at half speed, and a slow drift (px/s) that differs between the
## quiz and the menu so screen changes read as parallax.
const BACKDROP_INTENSITY := 0.4
const BACKDROP_PULSE_SPEED := 0.06
const BACKDROP_DRIFT_QUIZ := Vector2(2.4, 1.2)
const BACKDROP_DRIFT_MENU := Vector2(-1.6, 2.2)
## Nodes whose motion follows the Reduce-motion setting (apply_reduce_motion).
const MOTION_GROUP := &"ui_motion"
## Mirrors the setting for decoration that has no host to ask (hover shine,
## card lift, ring sweeps).
static var reduce_motion := false


static func make_circuit_backdrop(drift: Vector2 = BACKDROP_DRIFT_QUIZ) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = CIRCUIT_SHADER
	mat.set_shader_parameter("intensity", BACKDROP_INTENSITY)
	mat.set_shader_parameter("speed", BACKDROP_PULSE_SPEED)
	mat.set_shader_parameter("drift", drift)
	rect.material = mat
	rect.resized.connect(func(): mat.set_shader_parameter("rect_size", rect.size))
	rect.add_to_group(MOTION_GROUP)
	return rect


## Reduce motion: freezes the backdrop drift and pulses, the official card's
## border flow and the timer rings' light sweep. Each node in MOTION_GROUP
## either has set_motion(on) or a ShaderMaterial with a "motion" or
## "flow_strength" parameter.
static func apply_reduce_motion(tree: SceneTree, calm: bool) -> void:
	reduce_motion = calm
	for node in tree.get_nodes_in_group(MOTION_GROUP):
		if node.has_method("set_motion"):
			node.set_motion(not calm)
			continue
		var mat := (node as CanvasItem).material as ShaderMaterial
		if mat == null:
			continue
		if mat.shader == CIRCUIT_SHADER:
			mat.set_shader_parameter("motion", 0.0 if calm else 1.0)
		elif node.has_meta("flow_strength"):
			mat.set_shader_parameter("flow_strength", 0.0 if calm else float(node.get_meta("flow_strength")))


## The surface material of a control, created on first use. Glass, shine,
## current and flow are all parameters of this one material.
static func surface_material(ctrl: Control, radius: int = AppTheme.RADIUS) -> ShaderMaterial:
	var mat := ctrl.material as ShaderMaterial
	if mat != null and mat.shader == SURFACE_SHADER:
		return mat
	mat = ShaderMaterial.new()
	mat.shader = SURFACE_SHADER
	mat.set_shader_parameter("corner_radius", float(radius))
	ctrl.material = mat
	ctrl.resized.connect(func(): mat.set_shader_parameter("rect_size", ctrl.size))
	return mat


## Glass look on a control whose StyleBox fill is pair[1]: the top edge is
## lifted to pair[0] (vertical gradient) with a 1 px highlight under it.
static func add_glass(ctrl: Control, pair: Array = AppTheme.GRAD_SURFACE, radius: int = AppTheme.RADIUS, bevel: float = AppTheme.BEVEL) -> ShaderMaterial:
	var mat := surface_material(ctrl, radius)
	var top: Color = pair[0]
	var bottom: Color = pair[1]
	mat.set_shader_parameter("fill_lift", Vector3(top.r - bottom.r, top.g - bottom.g, top.b - bottom.b))
	mat.set_shader_parameter("bevel", bevel)
	return mat


## Left -> right gradient from the StyleBox fill toward pair[1] (primary
## button, official card). The label is not tinted.
static func add_tint(ctrl: Control, pair: Array, amount: float = 1.0) -> void:
	var mat := surface_material(ctrl)
	mat.set_shader_parameter("tint_to", pair[1])
	mat.set_shader_parameter("tint_amount", amount)


## One pulse of current around the border of a control with a surface
## material: after `delay`, the head runs the full outline in `duration`.
static func run_current(ctrl: Control, delay: float, duration: float, power: float, tail: float = 0.22) -> Tween:
	var mat := surface_material(ctrl)
	mat.set_shader_parameter("current_strength", power)
	mat.set_shader_parameter("current_tail", tail)
	var tw := ctrl.create_tween()
	tw.tween_interval(delay)
	tw.tween_method(func(v: float): mat.set_shader_parameter("current_pos", v), 0.0, 1.0 + tail, duration)
	tw.tween_callback(func(): mat.set_shader_parameter("current_pos", -1.0))
	return tw


## Slow endless light on the border; Reduce motion stops it.
static func add_border_flow(ctrl: Control, color: Color, strength: float = 0.8) -> void:
	var mat := surface_material(ctrl)
	mat.set_shader_parameter("flow_color", color)
	mat.set_shader_parameter("flow_strength", strength)
	ctrl.set_meta("flow_strength", strength)
	ctrl.add_to_group(MOTION_GROUP)


## Screen entrance: fade in over MOTION_SCREEN and slide MOTION_SLIDE_PX into
## place along x. Only for controls resting at x = 0 (a container child
## flush left, or an anchored full-rect node): the slide ends at 0.
## calm (Reduce motion): the fade only.
static func screen_enter(ctrl: Control, calm: bool, delay: float = 0.0) -> Tween:
	ctrl.modulate.a = 0.0
	ctrl.position.x = 0.0 if calm else AppTheme.MOTION_SLIDE_PX
	var tw := ctrl.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "modulate:a", 1.0, AppTheme.MOTION_SCREEN).set_delay(delay)
	if not calm:
		tw.tween_property(ctrl, "position:x", 0.0, AppTheme.MOTION_SCREEN).set_delay(delay)
	return tw


static func make_fx_layer() -> Control:
	var layer := Control.new()
	layer.name = "FxLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 40
	return layer


static func _layer_ready(layer: Control) -> bool:
	return is_instance_valid(layer) and layer.is_inside_tree() and layer.get_child_count() < MAX_LIVE_BURSTS


static func _to_layer(layer: Control, global_pos: Vector2) -> Vector2:
	return layer.get_global_transform().affine_inverse() * global_pos


static func spark_burst(layer: Control, global_pos: Vector2, color: Color, amount: int = 44) -> void:
	if not _layer_ready(layer):
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.8
	p.explosiveness = 0.95
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 380)
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 420.0
	p.damping_min = 60.0
	p.damping_max = 140.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(color, 0.0))
	ramp.add_point(0.3, color)
	p.color_ramp = ramp
	p.position = _to_layer(layer, global_pos)
	layer.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true


## Small puff of sparks parented to `host` (an answer card) at a local point.
## local_coords keeps the sparks riding along when the card moves after the
## re-layout or the phone scrolls to the verdict; z_index lifts them over the
## next card. Never a child of answers_box itself: that holds cards only.
static func card_burst(host: Control, local_pos: Vector2, color: Color, amount: int = 22, speed: float = 1.0) -> void:
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.local_coords = true
	p.z_index = 5
	p.amount = amount
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 220)
	p.initial_velocity_min = 90.0 * speed
	p.initial_velocity_max = 250.0 * speed
	p.damping_min = 120.0
	p.damping_max = 220.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color_ramp = _spark_ramp(color)
	p.position = local_pos
	host.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true

## Sparks shed along `path` (host-local points) over `duration`, like an
## electron running down a trace. The emitter moves; the sparks it has shed
## stay where they fell (local_coords off) and die within 0.25 s.
static func trail_sparks(host: Control, path: PackedVector2Array, duration: float, color: Color, amount: int = 8) -> void:
	if not is_instance_valid(host) or not host.is_inside_tree() or path.size() < 2:
		return
	var p := CPUParticles2D.new()
	p.local_coords = false
	p.z_index = 5
	p.amount = maxi(amount, 1)
	p.lifetime = 0.25
	p.spread = 180.0
	p.gravity = Vector2(0, 160)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.2
	p.color_ramp = _spark_ramp(color)
	p.position = path[0]
	host.add_child(p)
	p.emitting = true
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	var tw := p.create_tween()
	for i in range(1, path.size()):
		tw.tween_property(p, "position", path[i], duration * path[i - 1].distance_to(path[i]) / maxf(total, 0.001))
	tw.tween_callback(func(): p.emitting = false)
	tw.tween_interval(p.lifetime)
	tw.tween_callback(p.queue_free)

static func _spark_ramp(color: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(color, 0.0))
	ramp.add_point(0.35, color)
	return ramp


static func confetti(layer: Control) -> void:
	if not _layer_ready(layer):
		return
	var img := Image.create(7, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var p := CPUParticles2D.new()
	p.texture = ImageTexture.create_from_image(img)
	p.one_shot = true
	p.amount = 150
	p.lifetime = 3.4
	p.explosiveness = 0.3
	var w := maxf(layer.size.x, 200.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(w * 0.5, 4.0)
	p.position = Vector2(w * 0.5, -12.0)
	p.direction = Vector2.DOWN
	p.spread = 28.0
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 230.0
	p.gravity = Vector2(0, 240)
	p.damping_min = 10.0
	p.damping_max = 30.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 0.9
	p.scale_amount_max = 1.7
	var palette := Gradient.new()
	palette.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	palette.offsets = PackedFloat32Array([0.0, 0.17, 0.34, 0.5, 0.67, 0.84])
	palette.colors = PackedColorArray([CYAN, EMERALD, AppTheme.YELLOW_300, AppTheme.PINK_400, AppTheme.VIOLET_400, AppTheme.ORANGE_400])
	p.color_initial_ramp = palette
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.8, Color.WHITE)
	p.color_ramp = fade
	layer.add_child(p)
	p.finished.connect(p.queue_free)
	p.emitting = true


## Briefly swells the outer glow of a PanelContainer's StyleBoxFlat, then
## settles back to the style it had.
static func glow_pulse(panel: Control, color: Color, peak_size: int = 26, duration: float = 0.6) -> void:
	if not is_instance_valid(panel):
		return
	var base := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if base == null:
		return
	var glow := base.duplicate() as StyleBoxFlat
	glow.shadow_color = Color(color, 0.55)
	glow.shadow_size = peak_size
	panel.add_theme_stylebox_override("panel", glow)
	var tw := panel.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(glow, "shadow_size", base.shadow_size, duration)
	tw.parallel().tween_property(glow, "shadow_color", base.shadow_color, duration)


## pivot is a fraction of the size: left-aligned text in a full-width label
## pops from its left edge (0, 0.5), or it swells past the panel and is cut.
static func pop(ctrl: Control, amount: float = 1.08, duration: float = 0.22, pivot := Vector2(0.5, 0.5)) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size * pivot
	var tw := ctrl.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2(amount, amount), duration * 0.4)
	tw.tween_property(ctrl, "scale", Vector2.ONE, duration * 0.6)


## Slides a VBoxContainer child to `dx` px right of its slot (x = 0); 0 slides
## it home. Always an absolute target, never as_relative: the container resets
## the child to its slot on every re-sort, so a relative return leg lands off
## the slot and stays there, and cards drift apart hover by hover. One slide
## tween per control, so a quick enter/exit can't leave two fighting.
## duration 0 snaps.
static func slide_x(ctrl: Control, dx: float, duration: float = 0.12) -> Tween:
	if ctrl.has_meta("_slide_tween"):
		var old := ctrl.get_meta("_slide_tween") as Tween
		if old != null and old.is_valid():
			old.kill()
		ctrl.remove_meta("_slide_tween")
	if duration <= 0.0:
		ctrl.position.x = dx
		return null
	var tw := ctrl.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "position:x", dx, duration)
	ctrl.set_meta("_slide_tween", tw)
	return tw


static func electrify_title(label: Label) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = TITLE_SHADER
	label.material = mat
	label.resized.connect(func(): mat.set_shader_parameter("text_width", label.size.x))


static func add_shine(ctrl: Control) -> void:
	surface_material(ctrl)
	ctrl.mouse_entered.connect(func(): shine_sweep(ctrl))


static func shine_sweep(ctrl: Control, duration: float = 0.6, delay: float = 0.0) -> void:
	var mat := ctrl.material as ShaderMaterial
	if mat == null or reduce_motion:
		return
	var tw := ctrl.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_method(func(v: float): mat.set_shader_parameter("shine_pos", v), -0.3, 1.5, duration)


## Lightning-bolt outline centred on c, h pixels tall.
static func bolt_points(c: Vector2, h: float) -> PackedVector2Array:
	var s := h / 12.0
	return PackedVector2Array([
		c + Vector2(1.5, -6) * s, c + Vector2(-3.5, 1) * s, c + Vector2(-0.3, 1) * s,
		c + Vector2(-1.5, 6) * s, c + Vector2(3.5, -1) * s, c + Vector2(0.3, -1) * s,
	])
