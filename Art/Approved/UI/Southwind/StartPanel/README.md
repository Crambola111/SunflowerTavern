# 椰风岛开始面板与通用按钮

用户于 2026-10-12 确认改版并要求接入游戏。六张素材均为无字透明 PNG；地图名、天数、模式、目标、提示和按钮文案由 Godot 动态绘制。

| 文件 | 用途 |
|---|---|
| `UI_StartPanel_Southwind_v1.png` | 准备营业主面板，包含标题区、正文区和底部日期栏 |
| `UI_StartHeader_Southwind_v1.png` | 独立宽标题牌，供后续同风格面板复用 |
| `UI_Button_PrimaryWide_Southwind_v1.png` | 青色主操作按钮 |
| `UI_Button_SecondaryWide_Southwind_v1.png` | 米白次操作/通用文字按钮 |
| `UI_Button_DayTabWide_Southwind_v1.png` | 可容纳解锁条件的长日期按钮 |
| `UI_Button_IconSquare_Southwind_v1.png` | 关闭、上一页、下一页等方形图标按钮底 |

运行副本位于 `GodotProject/assets/ui/southwind/`。开始页按 1600×900 内部画布排版；主操作按钮高度 76px，日期按钮 280×68px。主面板和按钮均已进入 `ArtCatalog.UI_REGIONS`。
