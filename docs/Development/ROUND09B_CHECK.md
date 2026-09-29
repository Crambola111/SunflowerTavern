# 第9轮B验收

本轮任务：SPF-8双杯订单；检查与图鉴素材清单。

## 已执行

源码差异审阅、git diff --check；确认正式Day1/2客流、可见客人目录和已有美术未改动。

## 已编写未运行

DayOneChecks.Run调用CheckSpf8：接单创建恰好2杯/同owner；重复互动不重复下单；首杯无结算/图鉴且不重置耐心；暂停冻结；第二杯后饮用，一次整单价格/小费/连击/解锁；半单过期清理排队/出酒口/手持剩余杯；错杯不增进度；配置复制杯数并拒绝非法值。

本环境没有Unity/.NET/Mono，未执行C#测试，未编译和试玩。可在.NET 8环境运行 `dotnet run --project tools/day-one-checks`，或运行既有Unity Sunflower检查菜单。

## Unity待验收

独立测试配置使用CreateSpf8（正式Day1/2不含该客人）：对话两杯、座位0/2→1/2；一杯只递送、不提前喝/收款；第二杯送齐后饮用、仅一次结算。半单离店不残留杯子、暂停冻结、错杯无进度；回归Day1/Day2既有流程。

下一轮第10轮A编排Day3，Mimi/SPF-8进入正式客流。素材需求见CODEX_ART_REQUEST.md，无新增动画。
