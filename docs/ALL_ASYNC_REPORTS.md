# 全部 AI 解析异步化

> 本页“全部功能进入本机队列”的方案已被替代，不要执行下文旧迁移。
> 当前问事/每日一卦使用 [Vercel 云端解析轮询](CLOUD_POLLING_REPORTS.md)，命盘使用 [本机 Worker](NATAL_WORKER_ROUTING.md)。
> 原方案保留作历史说明，不代表当前生产接口的执行路径。

本次只改任务执行、复看和展示。当前积分价格、豆包模型、提示词、支付回调、排盘算法不变。

## 启用顺序

1. 确认没有正在生成的报告，暂停本机 AI Worker。不要中断付费任务。
2. 在 Supabase SQL Editor 执行 `supabase/ai_all_async_migration.sql`。此前应已执行 `schema.sql`、`ai_report_jobs.sql`、`points_migration.sql`、`ai_report_settlement_guard_migration.sql`。不要重新执行旧迁移覆盖新的 RPC。
3. 再执行 `supabase/ai_report_timeout_cron.sql`。它启用 Supabase `pg_cron`，按名称创建/更新每分钟检查的退款任务。最后查询应返回 `guoxue-ai-report-timeout` 且 `active=true`。重复执行不会创建重复定时任务。
4. 部署本次代码。Vercel 配置 `AI_ASYNC_REPORTS_ENABLED=true`；未设置时也默认开启。旧的 `AI_LONG_REPORTS_ENABLED` 不再决定全部解析是否异步。
5. 重启同一份代码的本机 Worker（原启动方式不变，命令为 `npm run worker:ai`）。Supabase 与方舟密钥仍仅放在服务端环境，不能用于 Flutter 构建。
6. 确认 `ai_report_worker_status.last_seen_at` 更新，再使用测试账号验证。

若暂未执行迁移，可先设置 `AI_ASYNC_REPORTS_ENABLED=false`，保留之前的同步链路；若同时保留 `AI_LONG_REPORTS_ENABLED=true`，命盘仍进入旧队列。不要把关闭全部异步当成 Vercel 能运行15分钟的方案。

Supabase Cron 官方说明：<https://supabase.com/docs/guides/cron>；安装说明：<https://supabase.com/docs/guides/cron/install>。
数据库定时检查已提供脚本，但本机离线测试无法代替生产环境 Cron 调度验收。

## 扣积分与执行

- 所有问事、每日一卦、八字、紫微、铁板使用既有队列。
- 接口校验价格和登录，数据库在一次事务里锁定、扣积分、写流水、创建订单与任务。成功后返回202和订单 ID，不等待模型。
- Worker 从数据库认领任务，流式接收豆包结果。只有完整有效正文才保存；空响应、拒绝解析、调用异常退积分。
- 前端每20秒查询自己的订单状态。关闭网页不会取消任务或再次扣积分；在“我的报告”可以继续查看，打开的详情也会自动更新。
- 相同请求 UUID 永久复用已有订单；同一内容在生成期间、完成后的两分钟内跨请求复用。修改问题属于新解析，不复用其他问题的订单。
- 任务无法插入时事务整体回滚，不会留下扣积分但无任务的孤立记录。
- 网络丢失不能证明提交失败：保留原请求 ID 重试，或查看“我的报告”，不要换请求 ID 反复提交。

## 15分钟规则

- `started_at`：Worker 首次认领时记录。
- `deadline_at`：开始执行时间加15分钟。心跳不会延长，重启不会重置。
- 执行到期限未完成，数据库不再接受成功结算，幂等退积分。重复检查不会重复退款。
- 尚未执行的排队任务另有30分钟上限；排队时间不消耗执行的15分钟。
- 数据库每分钟检查一次，正常情况下在超时后约一分钟内退款；报告查询和 Worker 也会触发检查。积压时每批处理20条，可能需要后续检查轮次。
- Worker 90秒没有心跳时，新解析在扣积分前拒绝。PC 必须开机、联网、不休眠才能执行新的解析；数据库定时退款不依赖 PC。
- 数据库不可用时不能承诺实时退款，恢复连接后会继续幂等处理。
- 成功订单不能被晚到的失败退款；已退款订单不能被晚到的成功改成完成。

## 每日一卦

- 以当前业务用户 ID + 服务端北京时间当天为键。每日只复用同一账号当天的生成中或成功报告。
- 页面进入时先读取 `GET /api/ai-report-daily`，恢复卦象与当天报告；正在生成则继续轮询。
- 已完成直接显示，不再要求点击解析；换设备也能恢复。
- 查询失败时不开放重复购买，显示重新读取入口。
- 旧的历史报告不删、不退款；迁移只为每个账号每天选一条可复看的成功/生成中记录作为当天入口。
- 已失败/退款允许重新提交。前一天的报告不阻止第二天解析。历史页复看不收费。
- 切换账号或退出时，旧请求的返回内容不会显示给新账号。

## 报告排版

正文按 Markdown 展示标题、段落、加粗、列表、表格，支持选择复制；不把数据库 JSON、提示词、支付参数放进报告。
模型返回的 HTML 不作为脚本执行，远程图片不自动加载。

## 本机验证命令

```powershell
npm run check:api
npm run test:server
$env:PGLITE_MODULE_PATH='D:\AIProjects\tool\guoxue-sql-audit\node_modules\@electric-sql\pglite'
npm run test:async-sql
node test/server_settlement_sql_test.js
flutter analyze --no-pub
flutter test test/features/ai_reports test/widget_test.dart --no-pub
flutter build web --release --no-pub
```

本地 PostgreSQL 测试使用独立内存库，不读取生产密钥、不改线上积分。Cron 扩展须在线上执行脚本后检查其运行记录。

2026-10-08 本机结果：API语法检查、10组服务端测试、异步队列SQL测试、既有结算/积分SQL测试均通过；Flutter静态检查无问题；报告与界面回归61项通过；Web发布构建成功（保留已有的 CupertinoIcons 字体提示，不阻断构建）。未做生产豆包调用或线上 Cron 调度验证。

## 人工验收

1. 点击任意解析，按钮立即进入提交中，接口返回订单后显示生成中；离开页面，在“我的报告”等待正文自动显示。
2. 同一问题重复提交或刷新后重试，流水只有一笔扣积分；已有报告免费复看。
3. 每日一卦解析完成后退出该页面，再进入，直接显示当天正文；换设备登录同一账号也能显示。
4. 退出账号 A 登录账号 B，不能看到 A 的报告。
5. 查看长报告的标题、列表和表格，手机端能正常阅读、复制。
6. 测试环境制造失败或缩短测试任务的 `deadline_at`，确认只出现一笔退款、晚到结果不覆盖。不要对真实用户的报告做破坏性测试。
7. Supabase Cron 页面检查 `guoxue-ai-report-timeout` 的最近运行结果为成功。关闭 Worker 后不会扣积分创建新任务。
