# 向日葵酒馆 · Godot 版

当前主工程：Godot 4.5.1 标准版 / GDScript / 原生 Control UI，无需 Unity 或 .NET。

1. 安装 Godot 4.5.1 标准版（本轮实测版本）。
2. 在项目管理器选择“导入”，打开本目录 `project.godot`。
3. 等待素材导入完成，按 F6 运行 island.tscn，或 F5 运行项目。
4. 准备页点击“开始营业”。左右键转向，Space互动；也可点击座位转向、再次点击互动。Esc暂停。
5. 接单 → 下方出酒口取杯 → 原客位送达 → 客人喝完后收钱。第1天达到70金币解锁第2天；第2天90、第3天140。

当前迁移已有的前三天与七客图鉴；Snowy/Jiwoo机制和图标已迁移，但第4天未编排，正式营业暂不可遇见。没有新增关卡或提前标记完成。

## 目录

- `scenes/island.tscn`：主场景。
- `scripts/island.gd`：原生界面、输入、对话、图鉴、商店、准备和结算。
- `scripts/tavern_model.gd`：不依赖场景树的营业状态与特殊客人规则。
- `data/days.json` / `guests.json`：排班、数值、饮品和小传。
- `scripts/art_catalog.gd`：座位Q版、对话/图鉴立绘、饮品图标独立映射。
- `scripts/progress_store.gd`：Godot本地存档。
- `assets/`：已引用的运行美术；不放Unity `.meta`。Godot `.import`和脚本`.uid`应随版本提交。
- `tests/`：可由Godot headless运行的回归与界面冒烟检查。

## 检查命令

```sh
godot --headless --path GodotProject --editor --import --quit
godot --headless --path GodotProject --script res://tests/regression.gd
godot --headless --path GodotProject --script res://tests/ui_smoke.gd
```

从仓库根目录执行。检查结果与限制见 `../docs/Development/GODOT_MIGRATION.md`。无界面测试不等于视觉验收。

## 存档

`user://progress_v2.json`保存钱包、装饰、图鉴、教学、小费余额、两模式的通关与最高收入；不续接半途营业。临时文件写完后替换正式文件，异常/未来版本停止写入并显示错误。没有云存档。

Godot不会自动读取Unity PlayerPrefs。如果从未玩过Unity版本，直接开始即可。

如需导入旧记录：在原Unity项目用菜单 `Sunflower > Export save for Godot` 导出 `unity_save.json`（只读旧数据），然后在仓库根目录执行：

```sh
godot --headless --path GodotProject --script res://scripts/import_unity_save.gd -- /absolute/path/unity_save.json
```

导入器拒绝覆盖已有Godot存档；先自行备份并移走旧Godot存档。Unity导出菜单尚未经过Unity实际编译，需当地验证。原Unity存档不会被删除。

## 美术状态

背景、桌前遮挡、按钮、对话框、图鉴书本、小葵现有静态/动作、5款饮品图标已迁移。Bobo/Coco/Horn/Tank/Gecko立绘用于对话和图鉴。

Bobo/Coco的已确认Seated_v1静态座位图已接入CHIBIS；其余七位客人的座位图待归档，暂用名字和状态按钮保持可玩，不拿精细立绘冒充Q版。无需客人行走、多方向或饮用序列帧。缺图见 `../docs/Development/CODEX_ART_REQUEST.md`。
