# 南风岛UI第五批：关闭、锁定、收款与队列组件

2026-09-29 22:16 用户确认前批并要求每批4–5件继续制作。本批5件待确认，未接入游戏。

| 文件 | 用途 |
|---|---|
| UI_Icon_Close_Southwind_v1.png | 关闭X，叠加通用圆按钮底 |
| UI_Icon_Lock_Southwind_v1.png | 未解锁图鉴/槽位等状态 |
| UI_Icon_Coin_Southwind_v1.png | 桌旁待收款提示，向日葵金币 |
| UI_QueuePanel_Southwind_v1.png | 制作队列空底板，槽位独立组合 |
| UI_DrinkSlot_Southwind_v1.png | 单个饮品槽，叠加已有饮品图标 |

内置image_gen逐件生成，使用主场景参考图与已确认暂停图标统一风格。PNG真透明，文字、进度、饮品和金额由引擎叠加。保留原稿；实际UI按Alpha包围盒裁切排版，等比缩放图标；矩形底板可在确认后制作九宫格导入配置。Alpha/尺寸已检查，九宫格和游戏内视觉验收未执行。

上一批Codex/Decorate/TurnLeft/TurnRight/Pause已于22:16确认，正式原稿在Art/Approved/UI/Southwind，Review副本仅留历史。下一批建议制作：姓名牌、制作中小牌、通用提示牌、青色按钮、米白按钮；已有金色按钮与对话框继续复用。

## 完整提示词

### Close

Use case: stylized-concept. Production Sunflower Tavern game UI asset, single isolated component on genuine transparent background. Reference1 approved gameplay UI, reference2 approved pause icon showing ivory cream, cocoa outline and delicate honey gold bevel language. Cozy polished hand-painted casual-game warm 3D shading, clean silhouette readable when small. No words, letters, numbers, labels, screenshot, watermark or scene. No external drop shadow. ICON ONLY. A single bold symmetric ivory X close symbol formed by two diagonal rounded bars, cocoa brown outline and fine gold bevel matching pause icon. Front orthographic flat graphic, centered in square canvas fits central 70%, balanced stroke lengths. No circle or button base.

### Lock

Use case: stylized-concept. Production Sunflower Tavern game UI asset, single isolated component on genuine transparent background. Reference1 approved gameplay UI, reference2 approved pause icon showing ivory cream, cocoa outline and delicate honey gold bevel language. Cozy polished hand-painted casual-game warm 3D shading, clean silhouette readable when small. No words, letters, numbers, labels, screenshot, watermark or scene. No external drop shadow. ICON ONLY. One front-facing small padlock, ivory-cream rounded square body, soft gold beveled edge, warm cocoa outline, sturdy rounded ivory shackle with genuine transparent hole, tiny simple dark keyhole centered. Centered in square canvas with safe margins. No button base, no keys, no chain.

### Coin

Use case: stylized-concept. Production Sunflower Tavern game UI asset, single isolated component on genuine transparent background. Reference1 approved gameplay UI, reference2 approved pause icon showing ivory cream, cocoa outline and delicate honey gold bevel language. Cozy polished hand-painted casual-game warm 3D shading, clean silhouette readable when small. No words, letters, numbers, labels, screenshot, watermark or scene. No external drop shadow. ICON ONLY. One circular gold coin for collect-payment state above a table. Front orthographic face, thick readable gold rim, warm amber edge, embossed simple sunflower emblem in center with broad rounded petals and round central seed disc. Restrained bright highlight from upper left, no glitter outside silhouette, no currency letters, no number, no pile. Centered in square canvas occupying 72% with transparent exterior.

### QueuePanel

Use case: stylized-concept. Production Sunflower Tavern game UI asset, single isolated component on genuine transparent background. Reference1 approved gameplay UI, reference2 approved pause icon showing ivory cream, cocoa outline and delicate honey gold bevel language. Cozy polished hand-painted casual-game warm 3D shading, clean silhouette readable when small. No words, letters, numbers, labels, screenshot, watermark or scene. No external drop shadow. FRAME ONLY. One empty wide horizontal cream parchment panel for the drinks production queue at bottom center of reference. Rounded rectangle about 3.2 times wider than tall, thin warm walnut rim and gold bevel. Smooth ivory cream blank interior. No slots, no drinks, no progress bars, no locks, no upper tab, no symbols, no decoration. Interior opaque, exterior transparent. Wide landscape canvas with safe margins. Front orthographic, corners suitable for nine-slice; preserve clean long straight edges and empty center. This is one background layer onto which separate drink slots will be placed.

### DrinkSlot

Use case: stylized-concept. Production Sunflower Tavern game UI asset, single isolated component on genuine transparent background. Reference1 approved gameplay UI, reference2 approved pause icon showing ivory cream, cocoa outline and delicate honey gold bevel language. Cozy polished hand-painted casual-game warm 3D shading, clean silhouette readable when small. No words, letters, numbers, labels, screenshot, watermark or scene. No external drop shadow. SLOT FRAME ONLY. One square softly rounded drink-slot tile matching queue bar in reference, pale cream interior with very subtle warm inset shading, slim honey gold rim and ivory bevel. Minimal understated recessed-slot appearance, broad blank center for runtime drink icon. No drinks, no locks, no progress ring, no label, no extra tile, no scenery. Opaque cream interior, transparent exterior, square canvas with safe margins. Front orthographic graphic, borders clean enough for nine-slice.
