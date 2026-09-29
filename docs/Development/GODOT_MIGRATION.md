# Unity → Godot 迁移验收

2026-09-29，用户确认 Godot 引擎 + AI、GDScript 路线。迁移批次 M1，不计作原计划第12轮；先迁移既有实现，后续轮次继续第一地图。

## 两项任务

- [x] 迁移工程、GDScript规则、界面、配置、存档与现有运行美术。
- [x] 执行Godot检查、整理文档与同步源文件树。

## 功能对照

| 原实现 | Godot入口 | 迁移结果 |
|---|---|---|
| DayConfiguration.cs | data/days.json、guests.json、day_config.gd | 前三天时长/目标/排班及9客配置保持；仅7客正式开放 |
| TavernModel.cs | tavern_model.gd | 接单、顺序制作、单杯手持、订单归属、送达、现金结账、连击、漏单清理、一次结算 |
| 特殊客人 | tavern_model.gd | Coco占位、Horn订单短显、Tank摘呼吸器、Gecko换座、Mimi偷钱、SPF8双杯、Snowy限时、Jiwoo时段/候座 |
| IslandScene.cs | scenes/island.tscn、island.gd | 键鼠输入、HUD、准备/重试/辅助、暂停/失焦、对话、图鉴、商店、教学与反馈 |
| PlayerPrefs | progress_store.gd | Godot user://版本化JSON；钱包/三装饰/图鉴/教学/两模式记录/小费余额 |
| 旧存档迁移 | GodotSaveExport.cs、import_unity_save.gd | 手动只读导出、验证后导入；禁止覆盖已有Godot存档 |
| Resources美术 | assets、art_catalog.gd | 原图字节不变；不迁移Unity `.meta`；Q版/立绘分离 |

## 实际检查

本环境成功下载并运行官方 Godot 4.5.1 Linux 标准版：

- [x] `--headless --editor --import --quit`：素材导入和脚本解析无错误。
- [x] `--headless --quit-after 10`：主场景启动无脚本错误。
- [x] `tests/regression.gd`：86项检查，0失败。两模式前三天完美服务结果分别5/7/9客、79/124/190金币；特殊机制、暂停、错误送达、重复结算、存档持久化与损坏保护。
- [x] `tests/ui_smoke.gd`：26项检查，0失败。实际创建场景、触发点单/购买按钮回调、切日/辅助重开/结算去重、锁定及解锁图鉴、5客立绘/5饮品加载、特殊客对话。
- [x] Godot旧存档JSON导入器：隔离目录中导入样例、重读钱包/图鉴、再次导入拒绝覆盖均通过；不代表Unity导出菜单已编译。
- [ ] 图形窗口中的字体、布局、遮挡、缩放、完整点击试玩尚未验收。当前环境没有显示服务器，不能把headless检查当作视觉验收。
- [ ] 桌面导出包、用户真实旧PlayerPrefs导出、Unity导出菜单编译尚未验收。

检查不是全量形式化等价证明；旧C#检查仍保留作历史对照，不再作为主工程测试入口。

## 当前已知边界

- Day4排班、第一地图结束和下一站提示原本未完成，本轮没有新增；Snowy/Jiwoo通过独立配置测试，尚未正式开放。
- Bobo/Coco座位静态Q版已随并行美术会话归档并接入；其余七位待归档，场内保留名字/状态按钮，不用精细立绘替代Q版。Bobo/Coco/Horn/Tank/Gecko立绘已用于对话和图鉴，其他4客独立稿待归档。
- 普通客人点单/空手回看订单弹窗，送达/收钱不弹额外对话；所有弹窗冻结计时。惊喜客人分支对话剧本和表情仍属后续工作，本轮只迁移已有订单对话。
- 三装饰购买和加成已迁移，实体摆件显示仍待第13轮。
- 小葵沿用现有D0/D2/D6及青柠递送素材，不补全八方向；脚底锚点/尺寸视觉复核待实机。
- UnityProject暂存为迁移对照和旧存档导出入口，停止新增功能；旧文档历史轮次保留，最新入口为GodotProject。

## 下一轮

先做Godot图形窗口试玩修正和已确认Q版接入；迁移验收后回到原计划第12A（Day4排班与9客图鉴），每轮仍最多两项任务。
