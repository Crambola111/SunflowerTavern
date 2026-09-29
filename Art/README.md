# 已确认美术目录

## 2026-09-29 20:47 用户确认：立绘与场内Q版分离

Tank、Gecko精细全身立绘已确认，归档 Art/Approved/Guests/Tank/Tank_Portrait.png 与 Art/Approved/Guests/Gecko/Gecko_Portrait.png，仅用于对话/图鉴详情。原稿1024×1536 RGBA，透明通道已检查，未接入Unity。

场内客位统一使用Q版静态全身图，文件建议 <ID>_Chibi.png；保留角色服装、物种、道具和有梗性格，缩小后轮廓清晰。先制作Tank/Gecko Q版供确认；Bobo/Coco/Horn已有Portrait不得默认视为合格Q版，需要核对并补齐；Mimi/SPF8/Snowy/Jiwoo同样区分两种用途。小葵已有Chibi/工作服体系，继续沿用。每人首版一张静态Q版，不追加行走/入场/多方向动画。头像可裁切。

本条覆盖历史“同一张Portrait用于场内、对话、图鉴”的要求。场内Chibi与对话/图鉴Portrait需要分别配置，待开发接入，不代表已完成代码修改或Unity验收。Q版待确认前不写入Approved、不覆盖现有运行文件。


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

## 方向素材制作进度（2026-09-29）

新增南风岛工作服 D6 左侧面、D2 右上背侧面静态预览，已修正多余花饰与配件方位，待用户确认，未写入 Approved 或运行目录。此前背面稿鸡蛋花左右位置须复核。八方向、统一512画布/脚底基准、单方向三帧服务序列尚未完成，不能作为连续动画直接接入。

已确认素材沿用第4轮A正式路径：默认服3张在 Approved/Sunny/Default/，南风岛待机在 UnityProject/Assets/Resources/IslandUI/。并行上传产生的 CharacterDesign 同名4张副本已清理，manifest 保持正式路径记录；未改动运行图片或 meta。

## 2026-09-29 已确认素材补同步

D0端杯与递送00/01/02于19:01获用户确认；D2右上背侧、D6左侧于18:45获确认。6张原稿归入 Art/Approved/Sunny/Southwind/，文件名标识方向和姿势。均为1254×1254 RGBA；设计确认不代表逐帧或Unity验收。512画布、比例/脚底对齐、透明边缘清理及托盘/杯分层尚待完成，无可编辑分层源文件，未修改运行素材及.meta。

后续规则：每次用户确认后，先同步并核验远端，再继续制作。其余方向稿未明确确认的仍保留待确认状态。

## 方向素材接入更新（第4轮B，2026-09-29）

用户已确认方向素材。本轮将 D2 配件修正版、D6 花饰修正版接入运行目录 Sunny_Southwind_D2_Idle.png / Sunny_Southwind_D6_Idle.png；来源和哈希见 manifest。上文“待用户确认”为历史状态，此处覆盖。原始1254×1254透明PNG保留，未重绘或镜像；显示高度和脚底由UI参数校准。D0沿用原路径，其余方向暂回退原待机图，不能称为完整八方向接入。其他方向稿和Carry/Serve仍待逐张归档与接入。

并行美术会话保留了D2/D6原稿副本，本轮保留以免覆盖他人上传；运行版本以UnityProject路径为准，后续统一清理重复归档。D0 Carry/Serve已确认并归档，下一轮接入。

## 第4轮C：青柠苏打端杯/递送接入
D0 Carry及Serve_00/01/02已复制至UnityProject/Assets/Resources/IslandUI，原始确认稿保留在Art/Approved/Sunny/Southwind用于追溯。manifest以source_path记录关系；运行只加载Resources。原PNG保持1254×1254和原哈希，未裁切重绘。
仅青柠苏打使用这组带固定饮品的动作图。正面动作暂用于各方向，非完整方向动画；其他饮品仍使用待机及原服务脉冲。共同显示比例/脚底已在UI中设置，Unity视觉验收未执行。后续优先补同方向其他饮品或角色/托盘/杯分层，并扩展方向动作。

## D6服务动作确认同步 · 2026-09-29 19:14

用户确认D6 Carry、Serve_00、Serve_01、Serve_02四张原稿；01/02采用持杯手修正版。归档 Art/Approved/Sunny/Southwind/，1254×1254 RGBA，青柠苏打与D0同杯型。设计已确认，512规格、脚底/比例对齐、透明边缘及Unity逐帧验收待完成。只同步原稿，不改变运行素材和.meta。确认后先同步并核验，再继续制作。

## 首日饮品确认同步 · 2026-09-29 19:21

用户确认芒果冰沙、椰子水、青柠苏打三张透明图标原稿，归档 Art/Approved/Drinks/Southwind/。设计已确认，256规格导出与Unity接入验收待完成。后续按用户要求制作全部地图饮品候选；未定义的后续地图菜单属于新提案，待确认，不视为已定玩法。



## 北欧饮品确认同步 · 2026-09-29 20:00

用户确认挪威冬季主题新版三款：越橘热饮（针织雪花杯套）、肉桂热可可（雪山松林釉杯）、极光莓果苏打（冰晶杯与青绿色极光）。原稿归档 Art/Approved/Drinks/Nordic/，版本v2；此前普通杯型预览不作为确认稿。1254×1254 RGBA，256导出及Unity接入/小尺寸视觉验收待完成。本次仅确认北欧三款，其余地图待确认稿不自动转为Approved。

## 前轮素材补接 · 2026-09-29

三款营业饮品（芒果冰沙、椰子水、青柠苏打）与小葵D6 Carry/Serve_00–02共7张确认原稿已接入IslandUI。保留1254原文件，不重绘/裁切；饮品由Unity导入器限制最大256纹理，实际导入效果待编辑器检查。D6仅用于面向P6、青柠苏打端杯/递送，其他方向沿用已有D0回退。manifest记录source_path及runtime_path；原稿保留作来源。

仓库尚无Tank/Gecko独立透明运行图；合影及整页UI参考不冒充可拆分成品。冰美式/夜间特调、北欧图标已确认归档，相关客人/地图尚未开放，本轮不改变菜单和客流。


## 前两张地图饮品确认补齐 · 2026-09-29 20:04

用户确认当前地图顺序中的南风岛和北欧全部已出饮品图标。本次补归档南风岛 Drink_IcedAmericano_v1.png（冰美式）和 Drink_NightMocktail_v1.png（夜间无酒精特调，菠萝薄荷装饰、粉橙渐变杯型）。南风岛5款与北欧3款共8款设计均已确认；北欧采用挪威冬季v2，旧版不采用。新增两张原稿1254×1254 RGBA，256导出与Unity接入验收待完成。希腊和星际图标仍待确认。

## 第11轮B饮品补接

冰美式Drink_IcedAmericano_v1、夜间无酒精特调Drink_NightMocktail_v1已按确认原稿原字节入UnityProject/Assets/Resources/IslandUI，附meta并登记manifest。代码复用订单/出酒口/手持/对话图标接口；Jiwoo正式来访仍待Day4编排。导入沿用Drink_最大256设置，Unity实际导入/透明边缘验收未运行。美术需求以docs/Development/CODEX_ART_REQUEST.md为准。

