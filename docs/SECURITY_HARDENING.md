# 国学万宝匣安全加固说明

本次加固目标是关闭公网内测阶段发现的主要风险：Supabase 直连读写、公开调试接口、短信滥发、伪造支付回调刷日志、AI 超长输入消耗。

## 必须执行的线上步骤

1. 在 Supabase SQL Editor 执行 `supabase/schema.sql`。
2. 确认业务表已开启 RLS，且 `anon` / `authenticated` / `public` 不再具备业务表读写权限。
3. Vercel Production 环境变量设置：
   - `NODE_ENV=production`
   - `CORS_ALLOWED_ORIGINS=https://guoxuewanbao.cn`
   - `ADMIN_DEBUG_TOKEN=<随机长字符串>`
   - `SMS_IP_MIN_INTERVAL_SECONDS=5`
   - `SMS_IP_MAX_PER_HOUR=30`
   - `SMS_GLOBAL_MAX_PER_MINUTE=120`
   - `PAY_NOTIFY_MAX_PER_MINUTE=60`
   - `AI_PROMPT_MAX_CHARS=16000`
   - `AI_SYSTEM_PROMPT_MAX_CHARS=6000`
   - `AI_INPUT_SNAPSHOT_MAX_CHARS=50000`
4. 重新部署 Vercel。

## 修复内容

- Supabase 业务表启用 RLS，并撤销 `public` / `anon` / `authenticated` 直连权限。
- `/api/auth-debug`、`/api/payment-debug` 在生产环境必须带 `ADMIN_DEBUG_TOKEN`，否则按接口不存在处理。
- API 错误详情以 `VERCEL_ENV=production` 或 `NODE_ENV=production` 为准隐藏。
- CORS 改为生产白名单，不再默认 `*`。
- 短信发送增加手机号、IP、全站分钟级频控，并记录失败发送尝试。
- 支付回调增加 IP 频控和请求体大小限制，日志内容会截断。
- AI 解析增加 prompt 和快照大小限制，避免超长输入消耗。

## 复测清单

- Supabase anon key 访问 `app_users`、`wallets`、`recharge_orders` 应被拒绝。
- 未带后台令牌访问 `/api/auth-debug`、`/api/payment-debug` 应返回 404。
- 未登录访问 `/api/wallet`、`/api/recharge-create`、`/api/ai-report-generate` 应返回 401。
- 短信同手机号、同 IP 高频发送应返回 429。
- 伪造支付宝/微信回调不得入账。
- 正常登录、钱包余额、支付宝充值、AI 扣费与失败退款流程仍可用。
