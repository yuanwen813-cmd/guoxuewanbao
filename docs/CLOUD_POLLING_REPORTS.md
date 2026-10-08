# Vercel 云端解析轮询

本次沿用每日一卦原有的云端解析、订单与积分结算逻辑，只把第一次请求改为先返回订单、随后轮询。问事、每日一卦、八字、紫微、铁板都不再依赖本机 AI Worker。价格仍为2积分，豆包模型、提示词、支付回调和排盘算法不变。

## 部署顺序

1. 确认没有正在生成的报告。完成或处理原队列任务后，可停止本机 Worker，不要中断付费解析。
2. 在 Supabase SQL Editor 执行 `supabase/ai_cloud_polling_migration.sql`。已有前置脚本为 `schema.sql`、`ai_report_jobs.sql`、`points_migration.sql`、`ai_report_settlement_guard_migration.sql`；不要重建表或重复旧脚本覆盖新函数。
3. 执行 `supabase/ai_report_timeout_cron.sql`。最后结果应显示 `guoxue-ai-report-timeout`、`* * * * *`、`active=true`。脚本按名称更新同一个定时任务，也回收旧 Worker 队列的超时订单。
4. 部署代码，依赖安装使用更新后的 `package-lock.json`，保留 Vercel Node.js 和 Fluid Compute。配置 `AI_CLOUD_POLLING_ENABLED=true`，不配置时也默认开启。仅更新环境变量后需要重新部署。
5. 原 `AI_LONG_REPORTS_ENABLED`、`AI_ASYNC_REPORTS_ENABLED` 不再控制当前解析接口，可以删除。无需 Worker 心跳、Worker 重启、`pg_net` 或增加新的 API Key。
6. 本机 Worker 关闭后，用测试账号完成下方验收。数据库脚本成功不代表 Vercel 后台生命周期已在公网验证。

如果临时回退同步响应，可设置 `AI_CLOUD_POLLING_ENABLED=false` 并重新部署。仍由 Vercel 执行，不切换到本机 Worker。每日复看和原子幂等规则保留。

## 执行与轮询

- Vercel 检查登录、价格、资料和模型配置，调用既有 `create_ai_report_debit_once`。钱包行锁、扣积分、订单、流水在同一个数据库事务中完成。
- 新订单通过 Vercel 官方 `waitUntil` 托管后续调用与结算，接口立即返回202、`pending=true`、订单 ID。不是无人托管的 fire-and-forget，也不是持续运行的 Node 服务。
- 相同请求 ID 返回原订单，不再调用模型或再次扣积分。同一内容在生成期间和完成后两分钟内也复用已有订单。
- 前端每20秒读取自己的报告状态。用户可以离开页面，从“我的报告”继续查看；本机关机不影响云端执行和查询。
- 完整有效正文保存为 completed；调用异常、超时、空响应、纯拒绝解析自动退款。仅短文或免责声明本身不会退款。
- 后台托管注册失败时不开始模型调用，按同一订单退款。提交连接失败或数据库返回丢失时，保留请求 ID 重新查询，不根据前端错误盲目重复扣积分。
- 正文保存状态不确定时只重试幂等结算，不再次调用模型，也不将可能已完成的报告盲目退款。

## 时限与兜底退款

当前 `vercel.json` 的函数最长300秒，豆包请求仍沿用原有最多270秒的超时，留出结算空间。`waitUntil` 不会延长这次函数的执行时限；本次不承诺15分钟模型持续执行，也不要求用户升级套餐。特别慢的命盘仍可能超时并退款。

Vercel 被强制终止时无法执行 catch。Supabase Cron 每分钟调用 `expire_stale_inline_ai_reports`，回收创建超过15分钟、仍生成中且没有 Worker 任务的订单。重复检查仅退一次；完成订单不被晚到失败退款，已退款订单不被晚到成功改为完成。15分钟是异常订单的回收窗口，不是函数的持续执行能力。每批最多20条，积压或数据库故障会延后处理。

Cron 在 Supabase 运行，不依赖浏览器、本机、Vercel Hobby 的每日 Cron，也不在前端存密钥。请在 Supabase Cron 中检查最近运行记录。

官方参考：[waitUntil](https://vercel.com/docs/functions/functions-api-reference/vercel-functions-package)、[后台任务仍受函数时限约束](https://vercel.com/kb/guide/troubleshooting-inconsistent-logs-in-vercel-functions)、[Supabase Cron](https://supabase.com/docs/guides/cron)。

## 每日一卦与报告

- 当前用户 + 服务端北京时间当天唯一。当天生成中或完成订单都复用，跨设备或更换请求 ID 不再次购买。
- 进入每日一卦先读取云端当天卦象和报告。已完成直接展示；生成中继续轮询；读取失败提供重读按钮，不放开重复购买。
- 新的一天不复用前一天报告，即使资料相同且仅相隔几分钟。已失败/退款后可以重新发起。
- 历史订单和旧报告不删除、不改原付款金额、不自动补退历史订单。迁移只选一条当天入口，重复执行保留既有选择。
- “我的报告”和解析区按 Markdown 排版标题、段落、列表与表格，可复制。不给用户展示数据库 JSON、支付参数或提示词；不执行模型 HTML 或加载远程图片。
- 退出或切换账号清除展示状态，旧账号的迟到响应不显示给新账号。

## 本机验证

```powershell
npm run check:api
npm run test:server
$env:PGLITE_MODULE_PATH='D:\AIProjects\tool\guoxue-sql-audit\node_modules\@electric-sql\pglite'
npm run test:async-sql
node test/server_settlement_sql_test.js
flutter analyze --no-pub
flutter test test/features/ai_reports test/features/ask_guidance test/widget_test.dart --no-pub
flutter build web --release --no-pub --web-renderer html --pwa-strategy=none --dart-define=GUOXUE_API_BASE_URL=https://guoxuewanbao.cn
```

数据库测试使用隔离内存库，不读取生产密钥。服务端测试模拟 Vercel 请求上下文，验证官方 SDK 注册、立即返回、只扣一次、失败退款和结算不确定状态；本机不能替代公网生命周期与 Cron 验收。

2026-10-08 本机验证：语法检查、11组服务端测试、隔离数据库迁移与结算测试通过；75项相关 Flutter 测试通过；静态检查无问题，正式 Web 构建成功。保留已有 Cupertino 字体提示，不阻断构建。未执行生产 SQL、部署、真实豆包消费或重新打包 APK。

依赖审计仍有1项既有阿里云短信依赖引入的 `moment@2.30.1` 中等风险提示，并非新增 Vercel 依赖引入；本次没有批量升级支付/短信依赖。后续应单独升级并回归短信登录。

## 用户验收

1. 不开启本机 Worker，用手机或另一台电脑登录网站。点击每日一卦解析，首次即显示生成中，并能进入“我的报告”。
2. 等待报告完成，核对流水只有一笔2积分扣除；回到每日一卦直接显示当天正文。
3. 退出页面、刷新或换设备，报告仍可查询；重复提交同一任务不新增消费。
4. 分别测试问事、八字、紫微和铁板。它们都走云端轮询；耗时超过当前执行限额时应显示退款，不无限等待或重复扣积分。
5. 换账号不能读到之前账号的报告；手机端标题、表格可读，复制不包含数据库 JSON。
6. 在测试库模拟失败或过期订单，确认自动退款一次、晚到结果不能覆盖退款。不要改真实用户的付费记录。
7. Supabase Cron 的最近运行记录应成功。生产豆包、网络耗时及实际退款由部署后的测试账号验收。
