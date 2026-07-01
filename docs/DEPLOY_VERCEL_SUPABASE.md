# 国学万宝匣 Vercel + Supabase 公网内测部署

## 目标

本部署用于第一版公网内测：用户账户、手机号验证码登录、服务端钱包、微信/支付宝充值订单、支付回调入账、AI 解析扣费与失败退款。

本项目当前不做会员权益系统，不做会员等级，不做订阅，不做积分，不做 VIP。

## 1. 创建 Supabase 项目

1. 在 Supabase 创建新项目。
2. 记录 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY`。
3. `SUPABASE_SERVICE_ROLE_KEY` 只能配置在 Vercel Serverless 环境变量中，不能进入 Flutter 前端。

## 2. 配置 Phone Auth

1. 在 Supabase Auth 中启用 Phone Provider。
2. 配置短信服务商。
3. 内测阶段如需 mock OTP，只能在非生产环境设置 `MOCK_OTP_CODE`。
4. Vercel Production 环境必须禁用 `MOCK_OTP_CODE`。

## 3. 初始化数据库

在 Supabase SQL Editor 中执行：

```sql
-- supabase/schema.sql
```

脚本会创建：

- `app_users`
- `wallets`
- `wallet_transactions`
- `recharge_orders`
- `ai_report_orders`
- `payment_notify_logs`
- `ai_call_logs`

并创建登录建档、充值入账、AI 扣费、AI 成功保存、AI 失败退款所需 RPC。

## 4. 创建 Vercel 项目

1. 将项目根目录指向 `D:\AIProjects\guoxueapp`。
2. 使用根目录 `vercel.json`。
3. 构建命令：

```bash
flutter build web --release --dart-define=GUOXUE_API_BASE_URL=$PUBLIC_API_URL
```

4. 输出目录：

```text
build/web
```

5. `/api/*` 由 Vercel Serverless Functions 承载。
6. 其他路径 fallback 到 `index.html`，支持 Flutter Web SPA 路由。

## 5. 配置环境变量

参考 `deploy/env.example` 分别配置 Vercel Development、Preview、Production。

必须只放在服务端的变量：

- `SUPABASE_SERVICE_ROLE_KEY`
- `DEEPSEEK_API_KEY`
- `WECHAT_PAY_PRIVATE_KEY`
- `WECHAT_PAY_API_V3_KEY`
- `ALIPAY_PRIVATE_KEY`

前端只通过 `GUOXUE_API_BASE_URL` 调用统一 API，不持有 DeepSeek Key、支付私钥或 Service Role Key。

## 6. 自定义域名

建议：

- Web：`https://your-domain.com`
- API：同域 `/api/*`，或 `https://api.your-domain.com`

如果 Web 与 API 分域，需要将 `PUBLIC_API_URL` 配置为 API 域名。

## 7. Web / App / 小程序 API 地址

Web 构建：

```bash
flutter build web --release --dart-define=GUOXUE_API_BASE_URL=https://your-domain.com
```

App 构建：

```bash
flutter build apk --release --dart-define=GUOXUE_API_BASE_URL=https://api.your-domain.com
```

小程序：

- request 合法域名配置为 `https://api.your-domain.com`
- 小程序端不得保存任何支付私钥或 DeepSeek Key
- 第一版仍使用手机号验证码登录

## 8. 微信支付配置

需要配置：

- `WECHAT_PAY_MCH_ID`
- `WECHAT_PAY_APP_ID`
- `WECHAT_PAY_MINI_APP_ID`
- `WECHAT_PAY_API_V3_KEY`
- `WECHAT_PAY_CERT_SERIAL_NO`
- `WECHAT_PAY_PRIVATE_KEY`
- `WECHAT_PAY_PLATFORM_CERT`
- `WECHAT_PAY_NOTIFY_URL`

notify_url：

```text
https://api.your-domain.com/api/pay-wechat-notify
```

第一版优先支持 `web_native` 扫码支付；`mini_program`、`app`、`h5` 已预留。

## 9. 支付宝配置

需要配置：

- `ALIPAY_APP_ID`
- `ALIPAY_PRIVATE_KEY`
- `ALIPAY_PUBLIC_KEY`
- `ALIPAY_NOTIFY_URL`
- `ALIPAY_GATEWAY`

notify_url：

```text
https://api.your-domain.com/api/pay-alipay-notify
```

第一版优先支持 Web 支付链接；`h5`、`app`、小程序已预留。

## 10. 充值订单和回调入账流程

1. 客户端调用 `/api/recharge-create`。
2. 服务端校验登录态和金额。
3. 服务端创建 `recharge_orders`，状态为 `pending`。
4. 服务端调用微信或支付宝下单。
5. 客户端展示二维码或支付链接。
6. 支付平台异步回调 `/api/pay-wechat-notify` 或 `/api/pay-alipay-notify`。
7. 服务端保存回调日志。
8. 服务端验签、校验订单号、校验金额。
9. 数据库事务中更新订单为 `paid`、增加钱包余额、写入 `wallet_transactions`。
10. 重复回调通过订单状态和流水唯一约束保证不重复入账。

## 11. AI 扣费和失败退款流程

1. 客户端调用 `/api/ai-report-generate`。
2. 服务端根据 `productId` 查价格，不能相信前端价格。
3. 余额不足直接返回，不调用 DeepSeek。
4. 余额足够时，数据库事务中扣钱包余额、写 `ai_debit` 流水、创建 `ai_report_orders`。
5. 事务提交后调用 DeepSeek。
6. 成功则保存报告内容，订单状态为 `completed`。
7. 失败则数据库事务退款，写 `ai_refund` 流水，订单状态为 `refunded`。
8. 报告复看通过 `/api/ai-report-detail` 查询，不重复扣费。

## 12. 上线前测试清单

- 手机号验证码发送和登录。
- 首次登录自动创建 `app_users` 和 `wallets`。
- 钱包余额读取。
- 钱包流水分页。
- 微信充值订单创建。
- 支付宝充值订单创建。
- 微信回调验签失败不入账。
- 支付宝回调验签失败不入账。
- 金额不一致不入账。
- 重复回调不重复入账。
- AI 余额不足不调用 DeepSeek。
- AI 成功扣费并保存报告。
- AI 调用失败自动退款。
- 报告复看不重复扣费。
- 页面不出现会员等级、VIP、积分、权益文案。
- Web / App / 小程序均调用同一套 API。
