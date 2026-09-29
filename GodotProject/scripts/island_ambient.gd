class_name IslandAmbient
extends Control

const WATER = preload("res://shaders/island_water.gdshader")
# Pixel anchors measured on the actual Island_Background.png, not the reference.
const SOURCE_SIZE := Vector2(1672,941)
const LIGHTS := [Vector2(848,189),Vector2(548,267),Vector2(1150,270),Vector2(331,451),Vector2(1355,452),Vector2(469,633),Vector2(1219,635),Vector2(630,704)]
var clock := 0.0
var reduced_motion := false
var water_material: ShaderMaterial
var settings_path := "user://ambient_settings.cfg"

func setup(background: TextureRect) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(1600,900)
	water_material = ShaderMaterial.new()
	water_material.shader = WATER
	background.material = water_material
	var settings := ConfigFile.new()
	if settings.load(settings_path) == OK:
		reduced_motion = settings.get_value("accessibility", "reduced_motion", false) == true
	apply_motion()

func set_reduced_motion(value: bool) -> Error:
	reduced_motion = value
	apply_motion()
	var settings := ConfigFile.new()
	settings.set_value("accessibility", "reduced_motion", value)
	return settings.save(settings_path)

func apply_motion() -> void:
	if water_material != null:
		water_material.set_shader_parameter("motion_amount", 0.0 if reduced_motion else 1.0)
	queue_redraw()

func advance(delta: float) -> void:
	if reduced_motion or delta <= 0 or not is_finite(delta):
		return
	clock += delta
	if water_material != null:
		water_material.set_shader_parameter("ambient_time", clock)
	queue_redraw()

func light_strength(index: int) -> float:
	return 0.78 + 0.10*sin(clock*2.3+index*1.71) + 0.06*sin(clock*3.71+index*2.43)

func _draw() -> void:
	if reduced_motion:
		return # The original baked lights remain; no flashing/static duplicate layer.
	var scale_to_view := size / SOURCE_SIZE
	for i in LIGHTS.size():
		var anchor: Vector2 = LIGHTS[i] * scale_to_view
		var strength := light_strength(i)
		var radius := 17.0 if i < 7 else 28.0
		for ring in range(8,0,-1):
			draw_circle(anchor, radius*ring/8.0, Color(1.0,0.62,0.16,0.009*strength))
		if i == 7:
			continue # Hanging woven lamp receives glow only, no exposed flame.
		var sway := sin(clock*2.1+i*1.7)*0.7
		draw_set_transform(anchor+Vector2(sway,-2),0,Vector2(1,1+0.08*sin(clock*2.9+i)))
		draw_colored_polygon(PackedVector2Array([Vector2(-2,3),Vector2(-1,-1),Vector2(sway,-6),Vector2(2,0),Vector2(2,3)]),Color(1,0.73,0.26,0.22*strength))
		draw_set_transform(Vector2.ZERO)
