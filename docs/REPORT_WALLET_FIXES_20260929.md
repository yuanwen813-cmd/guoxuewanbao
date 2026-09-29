# 积分钱包与 AI 报告修复（2026-09-29）

## 范围与状态

- [x] P1：切换账号时重新创建钱包状态，忽略旧请求；停止读取跨账号钱包缓存并清理旧缓存。
- [x] P1：区分 AI 失败与保存确认失败；有效报告完成后不可退款，退款后不可被迟到结果重新完成。
- [x] P2：按用户、产品、问题及原始资料保存请求编号；同一内容重试保留编号，改题使用不同编号。
- [x] P2：余额更新不再清空流水；解析后后台刷新流水，进入钱包时重新读取。
- [x] P2：报告列表支持分页及加载失败重试；旧报告只读查看，不触发生成或扣积分。
- [ ] 在生产 Supabase 执行本次迁移及验收脚本。
- [ ] 提交、推送、部署，以及新 APK 打包发布（本次未执行）。

保持不变：每次解析 2 积分、豆包模型及请求参数、提示词内容、正常生成入口、充值金额、历史订单和积分数值。没有新增收费档位。

## 必须先执行的数据库脚本

在已完成原积分迁移的 Supabase 项目中，依次执行：

1. `supabase/ai_report_settlement_guard_migration.sql`
2. `supabase/ai_report_settlement_guard_smoke_test.sql`

不要重新运行整个 `schema.sql` 或重新迁移积分。第一份脚本只替换报告完成和退款的两个函数，保留签名与服务端专用权限；不批量改变订单、积分或支付记录，可重复执行。

第二份脚本创建临时测试用户和订单，验证后回滚。成功返回 `AI_SETTLEMENT_SMOKE_TEST_PASSED`。包含：完成后误退款保护、重复保存只写一次日志、退款幂等、退款后迟到保存保护，以及历史空白报告退款。

发布顺序：执行 SQL 并验收成功，再发布 Web/API；最后按现有流程重打 APK。本次没有修改生产数据库。

## 保存失败的处理

AI 请求失败仍执行原退款流程。AI 内容已经生成，但报告保存响应丢失时，先读取订单核对，再最多重试一次相同内容的保存操作；不会再次调用豆包或扣积分。

数据库无法确认时返回已有任务编号，让页面继续查询，不凭一次网络错误宣称退款。数据库恢复后读取已保存报告；若从未保存成功，现有过期任务核对机制负责退款。已完成且有有效内容的报告不能被此流程退回。

## 自动测试

```powershell
npm run check:api
npm run test:server
flutter analyze --no-pub
flutter test test/features/ai_reports test/widget_test.dart --no-pub
flutter build web --release --no-pub --web-renderer html --pwa-strategy=none --dart-define=GUOXUE_API_BASE_URL=https://guoxuewanbao.cn
```

隔离 PostgreSQL 测试（不加载任何生产密钥）：将 `PGLITE_MODULE_PATH` 设置为本机安装的 `@electric-sql/pglite` 模块目录，然后运行 `node test/server_settlement_sql_test.js`。本机测试模块位于 `D:\AIProjects\tool\guoxue-sql-audit\node_modules\@electric-sql\pglite`，从 npm 现有缓存离线安装，未加入产品依赖。

该测试在内存 PostgreSQL 中执行数据库结构、任务队列、积分迁移、本次迁移（两遍）以及两份验收脚本，并验证匿名用户没有退款函数执行权限。它不代替生产 Supabase 上的部署验收或真实并发压测。

## 人工验收

1. A 账号查看积分及流水，退出后登录 B；B 页面不得显示 A 的积分、流水或充值订单。慢网下重复一次。
2. 点击解析后应立即显示“生成中”；报告价格仍为 2 积分，提示词和正常报告内容不变。
3. 正常解析后进入钱包，已有流水仍在，并能看到本次扣积分记录。失败退款应出现退款记录。
4. 请求断网后不改问题重试，应查询或继续原请求而非再次扣积分；改成另一个问题后可以提交独立请求。不同问题属于另一次解析，会按现价扣积分。
5. 报告超过 50 条时，到列表底部点击“加载更多报告”，可以打开更早的已付费报告；查看不扣积分。加载途中断网，恢复后重试不跳页。
6. 数据库故障模拟和退款边界使用上述隔离测试，不要为了验收主动破坏生产数据库或修改真实订单。

## 本次本机验证结果

- `npm run check:api`：通过。
- `npm run test:server`：全部 8 组通过，包含新增的保存响应丢失、状态不确定、请求冲突及分页测试。
- `flutter test test/features/ai_reports test/widget_test.dart --no-pub`：53 项通过。
- `flutter analyze --no-pub`：无问题。
- 隔离 PostgreSQL：迁移重复执行、报告完成/退款状态保护、旧空报告退款、服务端权限和原积分验收均通过。
- Web release 构建：成功。构建日志存在 CupertinoIcons 字体配置警告，没有阻断构建；本次没有修改字体配置。
- 定价、豆包客户端、提示词加载器及模板文件与本轮开始时一致；原有提示词和按钮即时反馈测试通过。
- 未调用真实豆包、未真实支付、未执行生产数据库迁移、未发布 Web 或 APK。没有声称已完成全项目所有测试或生产并发压测。
