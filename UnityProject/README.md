# 向日葵酒馆 · 当前 Unity 工程

Unity 6000.0.62f1，C# / uGUI，电脑横屏。

1. Unity Hub 添加本目录（包含 Assets、Packages、ProjectSettings）。
2. Active Input Handling 选择 Input Manager (Old) 或 Both。
3. 打开 Assets/Scenes/NanfengIsland.unity，Play 后开始营业。
4. 分别以1920×1080、1920×1200检查界面、座位点击与弹窗暂停。
5. Sunflower 菜单运行逻辑和第3轮美术检查；入口存在不代表已通过。

已编写：首日120秒营业、七座位、转向接单/自动制作/取送/收钱、首日三客行为、弹窗暂停、图鉴存档、三件装饰购买与加成。接入独立背景、小葵、Bobo/Coco/Horn、桌前遮挡及静态UI。

待完成：第2、3轮引擎验收；角色动画、装修实物、其他客人、Day 2–4、完整通关与可执行构建。本环境未运行 Unity 或 C# 编译器。

正式运行美术在 Assets/Resources/IslandUI/；Resources/Art/ 保留备用加载路径。设定与六张界面参考放在独立美术包，不重复导入工程。
