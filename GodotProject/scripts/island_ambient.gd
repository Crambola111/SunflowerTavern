class_name IslandAmbient
extends Control

const WATER = preload("res://shaders/island_water.gdshader")
const CANDLE_FLAME = preload("res://assets/CandleFlame_Southwind_v1.png")
const CANDLE_GLOW = preload("res://assets/CandleGlow_Southwind_v1.png")
# Pixel anchors measured on the actual Island_Background.png, not the reference.
const SOURCE_SIZE := Vector2(1672,941)
const LIGHTS := [Vector2(848,189),Vector2(548,267),Vector2(1150,270),Vector2(331,451),Vector2(1355,452),Vector2(469,633),Vector2(1219,635),Vector2(630,704)]
const LIGHT_PHASES := [0.00,0.17,0.41,0.63,0.84,0.29,0.72,0.53]
var clock := 0.0
var reduced_motion := false
var water_material: ShaderMaterial
var settings_path := "user://ambient_settings.cfg"
var flame_layers: Array[TextureRect] = []
var glow_layers: Array[TextureRect] = []

func setup(background: TextureRect) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(1600,900)
	water_material = ShaderMaterial.new()
	water_material.shader = WATER
	background.material = water_material
	build_light_layers()
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
	for layer in glow_layers:
		layer.visible = not reduced_motion
	for layer in flame_layers:
		layer.visible = not reduced_motion
	update_light_layers()

func advance(delta: float) -> void:
	if reduced_motion or delta <= 0 or not is_finite(delta):
		return
	clock += delta
	if water_material != null:
		water_material.set_shader_parameter("ambient_time", clock)
	update_light_layers()

func light_strength(index: int) -> float:
	var phase: float = LIGHT_PHASES[index] * TAU
	return 0.78 + 0.10*sin(clock*2.3+phase) + 0.06*sin(clock*3.71+phase*1.37)

func build_light_layers() -> void:
	var scale_to_view := size / SOURCE_SIZE
	for i in LIGHTS.size():
		var anchor: Vector2 = LIGHTS[i] * scale_to_view
		var glow := TextureRect.new()
		glow.texture = CANDLE_GLOW
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var glow_extent := 112.0 if i == 7 else 72.0
		glow.size = Vector2.ONE * glow_extent
		glow.position = anchor - glow.size * 0.5
		glow.pivot_offset = glow.size * 0.5
		add_child(glow)
		glow_layers.append(glow)
		if i == 7:
			continue # Hanging woven lamp receives glow only, no exposed flame.
		var flame := TextureRect.new()
		flame.texture = CANDLE_FLAME
		flame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		flame.size = Vector2(15,18)
		flame.position = anchor - Vector2(flame.size.x*0.5, flame.size.y*0.72)
		flame.pivot_offset = flame.size * 0.5
		add_child(flame)
		flame_layers.append(flame)
	update_light_layers()

func update_light_layers() -> void:
	for i in glow_layers.size():
		var strength := light_strength(i)
		glow_layers[i].modulate = Color(1.0,0.88,0.62,0.34*strength)
		var glow_pulse := 1.0 + 0.025*sin(clock*1.9+LIGHT_PHASES[i]*TAU)
		glow_layers[i].scale = Vector2.ONE * glow_pulse
	for i in flame_layers.size():
		var strength := light_strength(i)
		var sway := sin(clock*2.1+LIGHT_PHASES[i]*TAU)*0.9
		flame_layers[i].position.x += sway - float(flame_layers[i].get_meta("last_sway",0.0))
		flame_layers[i].set_meta("last_sway",sway)
		flame_layers[i].scale = Vector2(1.0-0.04*sin(clock*2.7+i),1.0+0.09*sin(clock*2.9+i))
		flame_layers[i].modulate = Color(1.0,0.92,0.74,0.72*strength)
