class_name ArtCatalog
extends RefCounted

# Explicit separation: a portrait is never silently substituted for an in-game chibi.
const PORTRAITS := {
	"bobo": "Bobo_Portrait", "coco": "Coco_Portrait", "horn": "Horn_Portrait",
	"gecko": "Gecko_Portrait", "tank": "Tank_Portrait",
	"ingrid": "Ingrid_KnittingGrandmother_Portrait_v1", "santa": "Nordic_Santa_Portrait_v1"
}
const CHIBIS := {
	"bobo": "Bobo_Seated_v1", "coco": "Coco_Seated_v1", "horn": "Horn_Seated_v1", "mimi": "Mimi_Seated_v1",
	"moose": "Moose_SnowCaptain_Seated_v1", "seal": "Seal_HarborCaptain_Seated_v1",
	"puffin": "Puffin_AuroraPhotographer_Seated_v1", "lynx": "Lynx_SkiCoach_Seated_v1",
	"squirrel": "RedSquirrel_CabinLandlord_Seated_v1", "raven": "Raven_WeatherReporter_Seated_v1",
	"reindeer": "WhiteReindeer_SleighNavigator_Seated_v1", "arctic_fox": "ArcticFox_SnowNightCourier_Seated_v1",
	"ingrid": "Ingrid_KnittingGrandmother_Seated_v1"
} # Approved static seated sprites; portraits remain independently mapped above.
const DRINKS := {"芒果冰沙": "Drink_MangoSlush_v1", "椰子水": "Drink_CoconutWater_v1", "青柠苏打": "Drink_LimeSoda_v1", "冰美式": "Drink_IcedAmericano_v1", "夜间无酒精特调": "Drink_NightMocktail_v1"}
const FUTURE_DRINKS := {"极光莓果苏打": "Drink_AuroraSoda_v2", "肉桂热可可": "Drink_CinnamonCocoa_v2", "越橘热饮": "Drink_LingonberryTea_v2"}
const DECOR_UI_ASSETS := {"panel": "UI_DecorShopPanel_Southwind_v2", "card": "UI_DecorShopCard_Southwind_v2", "purchase_button": "UI_DecorShopPurchaseButton_Southwind_v2"}
const CODEX_ASSETS := {"book": "UI_CodexBook_Southwind_v2", "locked_slot": "UI_CodexLockedSlot_Southwind_v2", "trait_badges": "UI_CodexTraitBadges_Southwind_v2"}
const DECOR_ASSETS := {
	"counter": "Decor_SW_Counter_v2", "chair": "Decor_SW_Chair_v2",
	"lighting": "Decor_SW_TableLamp_v2", "hanging_lamp": "Decor_SW_HangingLamp_v2",
	"railing": "Decor_SW_Railing_v2", "table": "Decor_SW_Table_v2", "deck": "Decor_SW_Deck_v2"
}
const NORDIC_DECOR_ASSETS := {
	"lantern": "Nordic_SnowRuneLantern_v1", "tabletop": "Nordic_KnotworkTabletop_v1",
	"chair_cover": "Nordic_WoolChairCover_v1", "fir_planter": "Nordic_FrostedFirPlanter_v1",
	"centerpiece": "Nordic_AuroraIceCenterpiece_v1", "railing": "Nordic_FjordRailing_v1"
}
const NORDIC_DECOR_ASSETS_BATCH2 := {
	"counter_front": "Nordic_CounterFront_v1", "aurora_pendant": "Nordic_AuroraPendant_v1",
	"menu_board": "Nordic_MenuBoard_v1", "seat_cushion": "Nordic_WoolSeatCushion_v1",
	"snow_deck_trim": "Nordic_SnowDeckTrim_v1", "ice_barrel_table": "Nordic_IceBarrelTable_v1"
}
var cache := {}

func texture(asset: String) -> Texture2D:
	if asset.is_empty():
		return null
	if not cache.has(asset):
		var path := "res://assets/" + asset + ".png"
		if not ResourceLoader.exists(path):
			path = "res://assets/ui/southwind/" + asset + ".png"
		if not ResourceLoader.exists(path):
			path = "res://assets/ui/nordic/" + asset + ".png"
		cache[asset] = load(path) if ResourceLoader.exists(path) else null
	return cache[asset]

func portrait(id: String) -> Texture2D:
	return texture(PORTRAITS.get(id, ""))

func chibi(id: String) -> Texture2D:
	return texture(CHIBIS.get(id, ""))

func drink(name: String) -> Texture2D:
	return texture(DRINKS.get(name, FUTURE_DRINKS.get(name, "")))

func decor(slot: String) -> Texture2D:
	return texture(DECOR_ASSETS.get(slot, ""))

func nordic_decor(slot: String) -> Texture2D:
	return texture(NORDIC_DECOR_ASSETS.get(slot, ""))

func nordic_decor_batch2(slot: String) -> Texture2D:
	return texture(NORDIC_DECOR_ASSETS_BATCH2.get(slot, ""))

func codex_asset(kind: String) -> Texture2D:
	return texture(CODEX_ASSETS.get(kind, ""))

func decor_ui(kind: String) -> Texture2D:
	return texture(DECOR_UI_ASSETS.get(kind, ""))

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

# Runtime atlas crops keep the approved PNG originals intact.
const UI_REGIONS := {
	"UI_Icon_Pause_Southwind_v1": Rect2(339, 312, 577, 630),
	"UI_Icon_Codex_Southwind_v1": Rect2(200, 157, 898, 961),
	"UI_Icon_Decorate_Southwind_v1": Rect2(159, 152, 976, 954),
	"UI_Icon_TurnRight_Southwind_v1": Rect2(111, 171, 1076, 928),
	"UI_Icon_TurnLeft_Southwind_v1": Rect2(133, 165, 996, 920),
	"UI_TimerPlate_Southwind_v1": Rect2(112, 143, 1836, 450),
	"UI_RoundButtonBase_Southwind_v1": Rect2(74, 72, 1106, 1098),
	"UI_MapNamePlate_Southwind_v1": Rect2(33, 143, 2090, 408),
	"UI_IncomeGoalPlate_Southwind_v1": Rect2(25, 158, 2125, 355),
	"UI_OrderBubble_Southwind_v1": Rect2(85, 105, 1465, 758),
	"UI_InteractButton_Southwind_v1": Rect2(57, 59, 1133, 1138),
	"UI_Icon_Close_Southwind_v1": Rect2(71, 53, 1073, 1129),
	"UI_Icon_Lock_Southwind_v1": Rect2(146, 51, 839, 1099),
	"UI_Icon_Coin_Southwind_v1": Rect2(87, 91, 1073, 1091),
	"UI_QueuePanel_Southwind_v1": Rect2(86, 78, 1816, 675),
	"UI_DrinkSlot_Southwind_v1": Rect2(138, 53, 1032, 1038),
	"UI_DialogueNamePlate_Southwind_v1": Rect2(107, 9, 1883, 730),
	"UI_BrewingBadge_Southwind_v1": Rect2(75, 23, 1834, 699),
	"UI_ToastPanel_Southwind_v1": Rect2(0, 9, 2009, 740),
	"UI_Button_Teal_Southwind_v1": Rect2(67, 25, 2085, 699),
	"UI_Button_Ivory_Southwind_v1": Rect2(100, 9, 1976, 677),
	"UI_CodexPortraitSlot_Southwind_v1": Rect2(33, 2, 1175, 1252),
	"UI_CodexSelectionFrame_Southwind_v1": Rect2(78, 37, 1098, 1138),
	"UI_CodexTag_Southwind_v1": Rect2(0, 19, 2160, 705),
	"UI_Button_PagePrevious_Southwind_v1": Rect2(122, 36, 1598, 813),
	"UI_Button_PageNext_Southwind_v1": Rect2(0, 31, 1758, 828),
	"UI_FavoriteDrinkCard_Southwind_v1": Rect2(0, 25, 1025, 1397),
	"UI_Icon_DialogueSkip_Southwind_v1": Rect2(136, 33, 1525, 782),
	"UI_SettlementPanel_Southwind_v1": Rect2(0, 0, 1104, 1373),
	"UI_SettlementTitle_Southwind_v1": Rect2(0, 0, 2172, 724),
	"UI_StatRow_Southwind_v1": Rect2(0, 9, 2158, 699),
	"UI_Badge_GoalSuccess_Southwind_v1": Rect2(0, 54, 1226, 1111),
	"UI_Badge_GoalRetry_Southwind_v1": Rect2(0, 47, 1228, 1207),
	"UI_ShopSidebar_Southwind_v1": Rect2(17, 15, 937, 1588),
	"UI_ShopItemCard_Southwind_v1": Rect2(0, 21, 1117, 1381),
	"UI_ShopSelectionFrame_Southwind_v1": Rect2(19, 27, 1091, 1375),
	"UI_PricePlate_Southwind_v1": Rect2(0, 23, 1910, 628),
	"UI_Icon_Bonus_Southwind_v1": Rect2(33, 51, 1297, 1070),
	"UI_StartPanel_Southwind_v1": Rect2(11, 26, 1637, 891),
	"UI_StartHeader_Southwind_v1": Rect2(7, 165, 2008, 485),
	"UI_Button_PrimaryWide_Southwind_v1": Rect2(21, 140, 2129, 427),
	"UI_Button_SecondaryWide_Southwind_v1": Rect2(0, 135, 2172, 433),
	"UI_Button_DayTabWide_Southwind_v1": Rect2(5, 77, 2161, 542)
}

func ui_texture(asset: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture(asset)
	if atlas.atlas == null:
		return atlas
	atlas.region = UI_REGIONS.get(asset, Rect2(Vector2.ZERO, atlas.atlas.get_size()))
	return atlas

func ui_style(asset: String, horizontal_margin := 36.0, vertical_margin := 24.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = ui_texture(asset)
	box.texture_margin_left = horizontal_margin
	box.texture_margin_right = horizontal_margin
	box.texture_margin_top = vertical_margin
	box.texture_margin_bottom = vertical_margin
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box
