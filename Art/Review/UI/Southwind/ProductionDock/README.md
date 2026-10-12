# 椰风岛底部制作区重组候选（5件）

状态：**用户已于 2026-10-12 确认并接入游戏；本目录保留审稿历史。** 正式原稿位于 `Art/Approved/UI/Southwind/ProductionDock/`。

本批不再用一个长面板承载所有信息，而是把制作区拆为稳定的五层。文字、秒数、队列数量、进度填充与饮品图标继续由 Godot 动态叠加。

| 文件 | 用途 | 建议运行尺寸 |
|---|---|---:|
| `UI_ProductionDock_Southwind_v1.png` | 底部制作区统一总底板；左侧主信息区、中部手持区、右侧出酒区 | 700×190 |
| `UI_ProductionTaskCard_Southwind_v1.png` | 当前制作饮品图标、名称、倒计时与排队数 | 335×112 |
| `UI_ProductionProgressFrame_Southwind_v1.png` | 空进度轨；填充由引擎绘制 | 255×34 |
| `UI_HeldDrinkSlot_Southwind_v1.png` | 手持饮品槽；左上手形徽记区分状态 | 92×92 |
| `UI_ReadyDrinkTray_Southwind_v1.png` | 出酒托盘；上箭头与微光表示可取杯 | 116×82 |

`QA_ProductionDock_InGame_v1.jpg` 是基于已确认主场景的合成预览，仅用于确认比例和层级，不是运行素材。

## 视觉规则

- 暖木、象牙白、柔金与深海蓝绿延续椰风岛现有 UI。
- 不在素材内写死中文、数字、饮品或进度，避免状态变化时重复出图。
- 主信息区负责“正在制作什么”；手形槽只表示“玩家手里有什么”；托盘只表示“出酒口有什么”。
- 五件均为 RGBA 透明 PNG；已裁除纯透明外边距。托盘保留柔和状态光晕，确认后接入时需在实机场景检查亮度。

## 生成方式

使用内置 image_gen，逐件生成。参考图为 `Art/Approved/UIReference/01_Gameplay.png`、既有队列/槽位/制作牌以及本批先生成的统一总底板。统一约束：单件透明底、无文字、无数字、无饮品、无人物、无水印、减少向日葵装饰、中心为动态内容留白。

