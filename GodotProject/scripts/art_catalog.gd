class_name ArtCatalog
extends RefCounted

# Explicit separation: a portrait is never silently substituted for an in-game chibi.
const PORTRAITS := {"bobo": "Bobo_Portrait", "coco": "Coco_Portrait", "horn": "Horn_Portrait", "gecko": "Gecko_Portrait", "tank": "Tank_Portrait"}
const CHIBIS := {} # Add confirmed *_Chibi sprites here as they enter the repository.
const DRINKS := {"芒果冰沙": "Drink_MangoSlush_v1", "椰子水": "Drink_CoconutWater_v1", "青柠苏打": "Drink_LimeSoda_v1", "冰美式": "Drink_IcedAmericano_v1", "夜间无酒精特调": "Drink_NightMocktail_v1"}
var cache := {}

func texture(asset: String) -> Texture2D:
	if asset.is_empty():
		return null
	if not cache.has(asset):
		var path := "res://assets/" + asset + ".png"
		cache[asset] = load(path) if ResourceLoader.exists(path) else null
	return cache[asset]

func portrait(id: String) -> Texture2D:
	return texture(PORTRAITS.get(id, ""))

func chibi(id: String) -> Texture2D:
	return texture(CHIBIS.get(id, ""))

func drink(name: String) -> Texture2D:
	return texture(DRINKS.get(name, ""))

func panel(asset: String) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture(asset)
	# Unity's source crop used a bottom-left origin; Godot uses top-left.
	box.region_rect = Rect2(136, 149, 1900, 419) if asset == "Button_Gold" else Rect2(35, 162, 2103, 416)
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		box.set_texture_margin(side, 160)
		box.set_expand_margin(side, 0)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		box.set_texture_margin(side, 110)
	# Draw at UI-sized margins instead of full-resolution source margins.
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.texture_margin_left = 16
	box.texture_margin_right = 16
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	return box
