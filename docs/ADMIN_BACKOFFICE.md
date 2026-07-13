# 国学万宝匣管理后台第一版

本轮后台只做账户权限、查询、手工余额调整和审计日志，不改前台用户主链路。

## 一、后台登录

后台登录使用手机号验证码，但不是所有用户都能进后台。

管理员手机号必须满足以下任一条件：

1. 配置在 Vercel 环境变量 `ADMIN_ALLOWED_PHONES` 中，多个手机号用英文逗号分隔；
2. 已存在于 Supabase `admin_users` 表，且 `status = active`。

后台登录接口会返回独立的 `admin:` 开头令牌，不复用普通用户 `app:` 登录令牌。

## 二、后台角色

第一版支持以下角色：

- `super_admin`：全部权限；
- `finance`：查询、余额调整、审计查看；
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

## 四、手工余额调整

手工余额调整只允许有 `wallet:adjust` 权限的管理员调用。

服务端会校验：

1. 调整金额必须是“分”为单位的非零整数；
2. 单次调整不能超过 `ADMIN_MAX_ADJUST_CENTS`；
3. 必须填写原因；
4. 扣减不能让用户余额变成负数。

数据库函数 `admin_adjust_wallet` 会在同一个事务中完成：

1. 锁定用户和钱包；
2. 更新钱包余额；
3. 写入 `wallet_transactions`；
4. 写入 `admin_audit_logs`。

## 五、部署配置

需要在 Vercel Production 环境变量中补充：

```text
ADMIN_ALLOWED_PHONES=管理员手机号1,管理员手机号2
ADMIN_JWT_SECRET=一段足够长的随机字符串
ADMIN_SESSION_TTL_SECONDS=43200
ADMIN_MAX_ADJUST_CENTS=100000
```

然后在 Supabase SQL Editor 重新执行 `supabase/schema.sql`，让 `admin_users`、`admin_audit_logs` 和 `admin_adjust_wallet` 生效。

## 六、边界

本轮没有加入会员系统、积分系统、优惠券系统，也没有改变前台充值、AI 扣费、历史记录、命盘、问事等用户侧流程。

