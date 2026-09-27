class_name UiFx
extends RefCounted

## Visual effects shared by the desktop and mobile layouts: shader backdrops,
## particle bursts, flashes and glow pulses. Everything here is decoration —
## no quiz state lives in these nodes, and every spawned node frees itself.

const CIRCUIT_SHADER := preload("res://src/fx/shaders/circuit_backdrop.gdshader")
const TITLE_SHADER := preload("res://src/fx/shaders/electric_title.gdshader")
const SHINE_SHADER := preload("res://src/fx/shaders/card_shine.gdshader")

const CYAN := AppTheme.SKY_400
const EMERALD := AppTheme.EMERALD_400
const RED := AppTheme.RED_400
const AMBER := AppTheme.AMBER_400

## Particle nodes alive on one fx layer are capped so rapid answering (or the
## headless harness answering hundreds of items without frames) can't pile up.
const MAX_LIVE_BURSTS := 8


static func make_circuit_backdrop(intensity: float = 1.0) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = CIRCUIT_SHADER
	mat.set_shader_parameter("intensity", intensity)
	rect.material = mat
	rect.resized.connect(func(): mat.set_shader_parameter("rect_size", rect.size))
	return rect


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


static func screen_flash(layer: Control, color: Color, peak: float = 0.12, duration: float = 0.4) -> void:
	if not _layer_ready(layer):
		return
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(color, peak)
	layer.add_child(rect)
	var tw := rect.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(rect, "color:a", 0.0, duration)
	tw.tween_callback(rect.queue_free)


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


static func pop(ctrl: Control, amount: float = 1.08, duration: float = 0.22) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size / 2.0
	var tw := ctrl.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2(amount, amount), duration * 0.4)
	tw.tween_property(ctrl, "scale", Vector2.ONE, duration * 0.6)


static func electrify_title(label: Label) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = TITLE_SHADER
	label.material = mat
	label.resized.connect(func(): mat.set_shader_parameter("text_width", label.size.x))


static func add_shine(ctrl: Control) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHINE_SHADER
	ctrl.material = mat
	ctrl.resized.connect(func(): mat.set_shader_parameter("rect_size", ctrl.size))
	ctrl.mouse_entered.connect(func(): shine_sweep(ctrl))


static func shine_sweep(ctrl: Control, duration: float = 0.6) -> void:
	var mat := ctrl.material as ShaderMaterial
	if mat == null:
		return
	var tw := ctrl.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float): mat.set_shader_parameter("shine_pos", v), -0.3, 1.5, duration)


## Lightning-bolt outline centred on c, h pixels tall.
static func bolt_points(c: Vector2, h: float) -> PackedVector2Array:
	var s := h / 12.0
	return PackedVector2Array([
		c + Vector2(1.5, -6) * s, c + Vector2(-3.5, 1) * s, c + Vector2(-0.3, 1) * s,
		c + Vector2(-1.5, 6) * s, c + Vector2(3.5, -1) * s, c + Vector2(0.3, -1) * s,
	])
