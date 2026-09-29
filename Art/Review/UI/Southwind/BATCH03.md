# 南风岛UI第三批：计时器与圆按钮底

2026-09-29 22:04 用户确认上一批并要求继续制作、上传。本批待用户确认，未接入Godot。

- UI_TimerPlate_Southwind_v1.png：右上计时底框，时钟为静态装饰图标，倒计时文字由引擎叠加。不要把静态指针当成真实计时数据。
- UI_RoundButtonBase_Southwind_v1.png：无图标圆按钮底，供后续图鉴/装修/转向等功能叠加图标。仅等比缩放。
- PNG真透明。保留原稿；布局使用Alpha有效区域，避免透明外边距导致UI过小。按下/悬停/禁用效果优先由程序处理。
- 内置image_gen，参考已确认的主场景图，木质金边。下一批：图鉴书本与装修椅子独立图标。
- 第二批MapNamePlate/IncomeGoalPlate于22:04已确认，正式版本在Art/Approved/UI/Southwind；本目录同名图仅为审稿记录。

## 完整提示词

### Timer

Use case: stylized-concept. Asset type: single production game UI timer frame, isolated true transparent PNG. Reference image is Sunflower Tavern approved gameplay screen; match the small TOP RIGHT countdown HUD exactly in material and spirit. One shallow horizontal warm brown wood capsule, delicate honey gold bevel, left attached round ivory clock icon with gold rim, minimal two dark brown hands and simple tick marks, no numerals. Clock is decorative icon, right 70% panel is completely blank dark warm wood for engine-rendered countdown. Overall silhouette about 3.4 times wider than tall including the slightly larger clock. Front orthographic, no tilt, crisp simplified details at small UI scale, cozy polished hand-painted casual-game 3D look. Entire object visible centered with safe transparent margins on wide canvas. No text, digits, colon, title, shadow outside silhouette, scene, second button, flower, or extra UI. Transparent outside; opaque inside.

### RoundBase

Use case: stylized-concept. Asset type: single reusable game UI round secondary button base, isolated true transparent PNG. Match the small wooden round buttons at bottom left and lower right of the approved Sunflower Tavern reference. One exact frontal circle. Thin honey gold beveled outer rim, warm walnut wood face with very subtle fine grain, darker brown center suitable for ivory overlay icons, restrained soft highlights from top left, softly rounded edge. The entire circular face is completely blank with no icons or letters. Cozy polished hand-painted casual-game 3D style. Clearly secondary brown wood, NOT the glowing yellow main action button. Single centered circle fills 84% of square canvas, full silhouette with safe transparent margins. True transparent exterior, opaque brown face. No shadow beyond silhouette, no scene, no arrow, no book, no chair, no palm, no screws, no flowers, no badges, no multiple states.
