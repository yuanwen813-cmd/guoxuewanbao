# 命盘 Worker 与云端问事分流

## 当前规则

- 问事、每日一卦：Vercel 调用豆包，首次返回订单，页面每20秒轮询。无需本机在线。
- 八字、紫微斗数、铁板神数：服务端原子扣积分、创建报告和队列任务，本机 AI Worker 以原豆包流式接口执行。前端仍立即进入生成中，可离开页面从“我的报告”查询。
- 价格仍为2积分，提示词、模型、出生资料、原始起卦时间、支付回调与每日一卦复看规则不变。
- Worker 离线超过90秒，没有新鲜心跳时，新命盘请求直接拒绝且不扣积分；不自动降级到5分钟云端执行。已有任务复看不要求 Worker 在线。

## 部署顺序

1. 确认没有正在生成的报告，再暂停旧 Worker。不要中断付费任务。
2. 在 Supabase SQL Editor 执行 `supabase/ai_natal_worker_migration.sql`。前置为已经完成的 `ai_cloud_polling_migration.sql` 及其前置脚本；不要重跑 `points_migration.sql`、`ai_all_async_migration.sql` 或重建表。
3. 原 `guoxue-ai-report-timeout` Cron 无需重新创建，继续每分钟检查云端遗留订单和 Worker 任务。新脚本只替换 `claim_ai_report_job`、`heartbeat_ai_report_job`、`settle_ai_report_job`、`expire_ai_report_jobs`，不覆盖云端扣费和每日一卦 RPC。
4. 部署本次代码。Vercel 保持 `AI_CLOUD_POLLING_ENABLED=true`，增加 `AI_NATAL_WORKER_ENABLED=true`（不配置也默认开启）。旧 `AI_LONG_REPORTS_ENABLED`、`AI_ASYNC_REPORTS_ENABLED` 不再控制分流。`AI_CLOUD_POLLING_ENABLED=false` 只改变问事/每日一卦的响应方式，不会关闭命盘 Worker。
5. 本机 `.env.local` 沿用已有 `SUPABASE_URL`、`SUPABASE_SERVICE_ROLE_KEY`、`ARK_API_KEY`、`ARK_BASE_URL`、`ARK_MODEL_ID`。只检查变量是否已配置，不公开密钥或把它们传入 Flutter 构建参数。
6. 在项目目录重新启动本机 Worker，使用已有后台启动方式或下面的前台命令。确认启动成功、数据库心跳刷新后再测试命盘。

```powershell
cd D:\AIProjects\guoxueapp
node --env-file=.env.local server/aiReportWorker.js
```

前台方式需要保持终端和电脑运行，并关闭自动睡眠；关机或停止 Worker 后不能执行新命盘任务。该命令使用 Node 20.6+ 的环境文件支持，无需再增加本地 HTTP 服务或开放本机端口。

## 时限与退款

- Worker 开始执行后最多15分钟，与 Vercel 的300秒函数上限无关。`ARK_TIMEOUT_MS=270000` 只控制云端请求，Worker 用任务剩余执行时间，不修改提示词或模型参数。
- 排队最多30分钟，排队时间不吃掉执行的15分钟。单进程按顺序执行，多个用户请求可能排队。
- 执行失败、拒绝解析、空响应或超过执行期限自动退回积分。相同请求复用订单，不再扣费；失败/退款后重新提交新请求。
- Worker 崩溃后，不重新认领同一运行中任务去重复请求模型，期限届满由 Supabase Cron 回收退款。心跳不延长执行期限；晚到成功不能覆盖已退款状态，晚到失败不能退款已完成报告。
- 云端遗留订单仍按原15分钟回收规则处理，回收时排除已有 Worker 任务，不误退仍在运行的命盘。
- 退款检查每分钟、每批最多20条，数据库故障或积压可能延迟处理。无需为了命盘调大 Vercel 函数时限。

## 验收

1. Worker 关闭并等90秒：问事、每日一卦仍正常；新命盘提示执行器未在线，积分不减少。
2. Worker 启动后：八字、紫微、铁板首次提交立即返回订单，在“我的报告”持续更新；重复点击只产生一笔扣积分。
3. 超过5分钟、但15分钟内的完整报告应可保存和复看；不要把前端轮询请求的短耗时当成模型执行耗时。
4. 模拟失败、执行过期、排队过期、晚到结算和重复结算时，积分只退一次。不要修改真实付费记录做破坏性测试。
5. 当天每日一卦已完成后直接复看，不再购买。已有报告的排版和账号隔离保持不变。

本机自动测试模拟模型调用，使用隔离 PostgreSQL 兼容数据库，不读取生产密钥或消费真实积分。线上脚本、Cron 与真实长报告需要部署后用测试账号验收。

2026-10-08 分流版本本机验证：语法检查和12组服务端测试通过；5组隔离数据库测试通过，覆盖云端版本升级、旧队列版本升级、重复迁移、15分钟期限、离线未扣积分、原子回滚及云端 RPC 未改动。本次未改 Flutter 页面，没有重打 Web/APK，也未执行生产迁移、重启真实 Worker 或推送部署。
