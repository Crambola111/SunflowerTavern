# 南风岛UI第二批：顶部信息牌

2026-09-29 用户要求制作下一批并上传。本批上传到Review供确认，不代表已经接入游戏。

- UI_MapNamePlate_Southwind_v1.png：左上地图/营业日木牌，向日葵装饰；留空文字。
- UI_IncomeGoalPlate_Southwind_v1.png：顶部金币/目标信息牌；留空动态数值。
- PNG真透明，保持比例缩放；透明外边距需要在引擎按Alpha有效区域裁切后排版，不把整个画布高度当成UI高度。不要伸缩金币和向日葵。文本由Godot叠加。
- 内置image_gen生成，参考用户确认的01_Gameplay图。下一批：计时器底框与次级圆按钮底。

## 完整提示词

### MapName

Use case: stylized-concept. Production game UI cutout, single isolated wide shallow wooden map-name plaque matching TOP LEFT label in reference. Front orthographic view. Rounded horizontal warm walnut wood plaque with thin honey-gold beveled border, one small sunflower with two green leaves attached to left edge. Rich brown blank interior for pale engine-rendered text; no text or numbers anywhere. Overall panel width five times height excluding flower. Delicate restrained warm 3D hand-painted casual-game shading, same reference materials. Entire item visible centered, tight sensible transparent margins. TRUE alpha transparent background outside plaque, opaque wood inside. No scene, no other buttons, no mockup, no lettering, no metal screws, no huge decorative flowers. Flower occupies only left 15%, rest empty readable wood. Wide landscape canvas.

### Income

Use case: stylized-concept. Production game UI cutout, single isolated wide shallow income/goal HUD plaque matching TOP CENTER label in reference. Front orthographic view. Horizontal cream capsule inset with warm brown wooden outer rim and thin gold beveled edging. Left end has single raised shiny golden coin emblem with simple sun motif, no text. Remaining 80% blank smooth ivory parchment interior for engine-rendered income and target; very subtle slim gold vertical divider at 60% panel width. Overall panel width six times height, keep slim elegant proportions. Delicate warm 3D hand-painted casual-game UI materials matching reference. Single item fully visible centered on wide landscape canvas with minimal transparent margins. TRUE alpha transparent background outside plaque, opaque interior. No letters, numbers, labels, scene, extra panels, huge thickness or ornate decorations.
