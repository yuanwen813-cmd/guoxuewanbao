# 积分制迁移与验收

本次只改变账户余额和 AI 消费的单位，不删除已有人民币分账本或充值订单。充值订单的 `amount_cents` 始终是实付人民币分。旧余额按照 1 元 = 1 积分迁移；旧数据有角/分时，保留到 0.01 积分。

## 上线顺序

1. 备份 Supabase 数据库，暂停真实充值回调和 AI 新订单，记录迁移前 `wallets` 总余额、已支付订单数、流水数。
2. 确认已经执行 `schema.sql`、`ai_report_jobs.sql`；在 SQL Editor 执行 `supabase/points_migration.sql`。**不要在此后单独重跑旧版 `schema.sql`**，它包含旧赠送函数。若要重建新环境，顺序为 `schema.sql`、`ai_report_jobs.sql`、`points_migration.sql`。
3. 执行 `supabase/points_smoke_test.sql`，确认输出 `POINTS_SMOKE_TEST_PASSED`；脚本最后 `rollback`，不会留下测试用户和订单。
4. 部署本次 Vercel API 和 Flutter Web，同步发布 `1.0.0+3` 新版 APK。新版页面会把积分与人民币实付金额分开展示。旧 APK 缺少积分确认字段，服务端会拒绝解析请求并提示更新应用，不会按旧人民币文案扣积分。
5. 恢复充值与 AI 请求，分别用新账号、已有账号、支付回调和 AI 失败场景测试。观察积分流水与监控。

## 迁移内容

- `app_users.registration_bonus_eligible`：新增账号默认为可领取；迁移前已存在的账号一次性标记为不可领取。确有证据从未领取的老账号，可由管理员审核后单独处理，不会自动补送。
- `app_users.registration_bonus_claimed_at`：领取标记。历史的 7 月 30 日前赠送流水会回填此时间；每次领取还受行锁、标记和积分流水唯一索引限制。
- `wallets.points_balance`：由旧 `balance_cents / 100` 自动生成，只读，无双账本漂移。旧整数分现在也作为积分的百分之一单位。
- `points_transactions`：由旧流水回填，后续由数据库触发器随钱包流水在同一事务中写入；包含积分变动、前后余额、类型和关联单据。旧库存在钱包现值与旧流水总和不一致的账户，迁移会追加 `MIGRATION_OPENING` 期初对账记录，但**不会增加或减少钱包余额**，也不会改写历史人民币订单。
- `ai_report_orders.request_id`：客户端请求幂等键，同用户唯一。
- `ai_report_orders.charge_unit`、`price_points`：历史记录标记人民币，新增记录标记积分；`price_cents` 保留兼容。
- `create_ai_report_debit_once`、`start_ai_report_job_once`：同一请求标识重试返回原订单；同一用户、产品和内容在生成中或完成后 2 分钟内也不会再扣一次。扣积分、流水、报告和长任务在事务内完成，失败整体回滚。前端等待超时后保留请求标识以便安全重试。
- `analysis_all_2_<功能名>` 是新增的 2 积分整体概览产品；页面确认后才请求服务端。原 AI 重点解析保持 5 积分。两种产品都由服务端按产品 ID 定价，客户端价格字段只用于防止旧页面误扣费。
- `expire_stale_inline_ai_reports`：Vercel 函数意外中止且超过 15 分钟仍未完成的非队列报告，由运行中的本地 AI Worker 每 5 分钟扫描退款；用户访问钱包/报告时也会触发兜底。Worker 停止期间，退款需等用户再次访问或 Worker 恢复。长报告仍由原队列过期逻辑处理。

## 关键核对 SQL

```sql
select count(*) as legacy_count from wallet_transactions;
select count(*) as points_from_legacy_count from points_transactions
where wallet_transaction_id is not null;
select count(*) as opening_entries from points_transactions
where transaction_type = 'MIGRATION_OPENING';
select count(*) as mismatch_count from wallets
where points_balance <> balance_cents::numeric / 100;
select count(*) as duplicate_bonus_users from (
  select user_id from points_transactions
  where transaction_type = 'REGISTER_BONUS'
  group by user_id having count(*) > 1
) x;
select count(*) as duplicate_recharge_credits from (
  select ref_id from wallet_transactions
  where type = 'recharge' group by ref_id having count(*) > 1
) x;
```

`legacy_count` 与 `points_from_legacy_count` 应相等，其他 mismatch/duplicate 计数应为零。当前生产库只读检查时有 6 个钱包、131 条旧流水、5 笔已付充值、3 条旧赠送记录；6 个钱包的现值都与旧流水求和不一致，所以预计会有 6 条期初对账记录。上线前请重新核对实际计数。充值订单的 `amount_cents` 没有转换或改写。支付回调仍需验签、校验平台实付金额与服务端订单金额；前端传的积分数量不能入账。

## 测试与限制

`npm run check:api`、`npm run test:server`、Flutter 测试与 Web 构建在本地执行。只有迁移在目标 Supabase 执行后，才能确认 PostgreSQL 行锁、唯一索引、触发器和长任务回滚在真实环境里有效。不要对真实商户回调接口发送伪造成功通知测试。
