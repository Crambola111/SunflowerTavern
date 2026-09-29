# 开发与同步约定

- 每轮最多两个任务，当前只做第一地图；遵循 docs/Development/map-01-godot-plan.md。
- 用户授权每轮开发后自动同步到 Crambola111/SunflowerTavern 的 main 分支，不继续往旧仓库发布。
- 同步源文件树，不用轮次ZIP替代仓库源码。Godot .import 和 .uid 跟随源文件；旧Unity .meta保留，不随意重建GUID。
- 代码变更同步相关游戏规则；角色变更同步人物设定；美术更新同步 Art 清单和运行接入状态；每轮更新 STATUS.md 和 CHANGELOG.md。
- 主工程为GodotProject，使用GDScript；UnityProject仅历史对照和旧存档导出。运行素材只放 GodotProject/assets 等工程目录，参考/原稿放 Art，避免重复副本。未确认素材明确标记，不覆盖正式资产。
- 不提交 Library/、Temp/、Logs/、obj/、构建产物、凭据、历史ZIP；保留他人远端修改，不强推。
- 实际执行检查后才能标记通过。最终回复列已完成、已验证、待验收、下一步及美术缺口。
