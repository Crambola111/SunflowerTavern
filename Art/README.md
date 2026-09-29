# 已确认美术目录

## 游戏运行素材

位于仓库 UnityProject/Assets/Resources/IslandUI/，保留原路径与 meta。

| 文件 | 用途 |
|---|---|
| Island_Background.png | 海岛背景 |
| Sunny_Chibi.png | 金棕双马尾小葵静态角色 |
| Bobo_Portrait.png | 海牛 |
| Coco_Portrait.png | 寄居蟹 |
| Horn_Portrait.png | 犀鸟原始透明图 |
| TableFront_Combined.png | 七桌合并前景遮挡 |
| Dialogue_Panel.png | 对话面板 |
| Button_Gold.png | 金色按钮 |
| Codex_Book.png | 图鉴书本 |

## 确认参考图

本目录 Approved/：

- CharacterDesign/Sunny_TwinTails_Design_v2.png：小葵完整设定。
- UIReference/：01_Gameplay、02_Arrival、03_Dialogue、04_Codex、05_Settlement、06_Decoration，六张界面参考。
- WorldReference/IslandReference.jpg、GuestLineup.jpg：场景和客人阵容。人设冲突以双马尾小葵设定为准，合影不作为透明立绘。

manifest.json 记录图片尺寸与 SHA-256，供版本核对。

## 排除与待补

白底客人 JPEG 不冒充透明图；位置不匹配的重绘桌图不替代原遮挡；原分桌包损坏 P3 未导入，使用完好合并图。旧小葵/旧场景移至历史归档。

优先补小葵转向/服务动作、客人入离场素材；后续客人、饮品图标、三件装饰实物按 docs/Development/map-01-art-production.md 分批制作。静态图已接入，Game View 比例、边缘和遮挡仍待验收。

## 新增已确认小葵（第4轮A）

原始确认包：SunflowerTavern_Art_Confirmed_20260929.zip，Library ID libfile_42b515f36cb48191bb75c26b5bdadf6f，版本0。
海岛服待机：UnityProject/Assets/Resources/IslandUI/Sunny_Southwind_Idle_v1.png（运行接入）。默认服3张：Art/Approved/Sunny/Default/（动作参考，未接入连续动画）。原图复制，未重绘或抠图；缩小边缘、脚底与画风待引擎验收。
包内分桌P3、P6无法完整解码，未导入；继续使用完好 TableFront_Combined。Horn已有正式图，本次不重复导入。
