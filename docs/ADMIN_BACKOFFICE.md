# 国学万宝匣管理后台第一版

本后台负责账户权限、查询、手工积分调整和审计日志；充值订单的实付金额仍以人民币记录。积分迁移与操作顺序见 [积分迁移说明](POINTS_MIGRATION.md)。

## 一、后台登录

后台登录使用手机号验证码，但不是所有用户都能进后台。

管理员手机号必须满足以下任一条件：

1. 配置在 Vercel 环境变量 `ADMIN_ALLOWED_PHONES` 中，多个手机号用英文逗号分隔；
2. 已存在于 Supabase `admin_users` 表，且 `status = active`。

后台登录接口会返回独立的 `admin:` 开头令牌，不复用普通用户 `app:` 登录令牌。

## 二、后台角色

第一版支持以下角色：

- `super_admin`：全部权限；
- `finance`：查询、积分调整、审计查看；
- `support`：查询、审计查看；
- `content`：查询；
- `viewer`：查询。

## 三、后台 API

认证：

- `POST /api/admin-auth-send-code`
- `POST /api/admin-auth-verify-code`
- `GET /api/admin-me`

概览与查询：

- `GET /api/admin-dashboard`
- `GET /api/admin-users`
- `GET /api/admin-user-detail`
- `GET /api/admin-wallet-transactions`
- `GET /api/admin-recharge-orders`
- `GET /api/admin-ai-report-orders`
- `GET /api/admin-ai-report-detail`

调账与审计：

- `POST /api/admin-wallet-adjust`
- `GET /api/admin-audit-logs`

## 四、手工积分调整

手工积分调整只允许有 `wallet:adjust` 权限的管理员调用。

服务端会校验：

1. 调整值必须是“百分之一积分”为单位的非零整数；
2. 单次调整不能超过 `ADMIN_MAX_ADJUST_CENTS`（沿用兼容环境变量名）；
3. 必须填写原因；
4. 扣减不能让用户积分余额变成负数。

数据库函数 `admin_adjust_wallet` 会在同一个事务中完成：

1. 锁定用户和钱包；
2. 更新积分余额；
3. 写入 `wallet_transactions`，由数据库触发器同步 `points_transactions`；
4. 写入 `admin_audit_logs`。

## 五、部署配置

需要在 Vercel Production 环境变量中补充：

```text
ADMIN_ALLOWED_PHONES=管理员手机号1,管理员手机号2
ADMIN_JWT_SECRET=一段足够长的随机字符串
ADMIN_SESSION_TTL_SECONDS=43200
ADMIN_MAX_ADJUST_CENTS=100000
```

新环境按部署指南执行 `schema.sql`、`ai_report_jobs.sql`、`points_migration.sql`。已有积分环境**不要重新执行 `schema.sql`**；本后台的表与函数如已存在，无须再初始化。

## 六、边界

当前没有会员系统或优惠券系统。积分制已单独上线；这里早期的“余额”是兼容字段名，实际调整单位应按积分理解，人民币支付订单不得改写。
