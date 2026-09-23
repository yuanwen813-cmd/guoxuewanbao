# 国学万宝匣 Vercel + Supabase 公网内测部署

## 目标

本部署用于第一版公网内测：用户账户、手机号验证码登录、服务端钱包、微信/支付宝充值订单、支付回调入账、AI 解析扣费与失败退款。

本项目当前不做会员权益系统，不做会员等级，不做订阅，不做积分，不做 VIP。

## 1. 创建 Supabase 项目

1. 在 Supabase 创建新项目。
2. 记录 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_SERVICE_ROLE_KEY`。
3. `SUPABASE_SERVICE_ROLE_KEY` 只能配置在 Vercel Serverless 环境变量中，不能进入 Flutter 前端。

## 2. 配置手机号短信登录

1. 当前生产短信登录使用阿里云短信服务 API 发送验证码。
2. 在阿里云短信服务中完成签名和验证码模板审核。
3. Vercel 中配置 `ALIYUN_ACCESS_KEY_ID`、`ALIYUN_ACCESS_KEY_SECRET`、`ALIYUN_SMS_SIGN_NAME`、`ALIYUN_SMS_TEMPLATE_CODE`。
4. 验证码只保存哈希，不在数据库中保存明文。
5. 内测阶段如需 mock OTP，需要同时设置 `ENABLE_MOCK_OTP=true` 和 `MOCK_OTP_CODE`。
6. Vercel Production 正式上线前必须删除 `ENABLE_MOCK_OTP` 和 `MOCK_OTP_CODE`。

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
- `ARK_API_KEY`
- `WECHAT_PAY_PRIVATE_KEY`
- `WECHAT_PAY_API_V3_KEY`
- `ALIPAY_PRIVATE_KEY`

前端只通过 `GUOXUE_API_BASE_URL` 调用统一 API，不持有 火山方舟 API Key、支付私钥或 Service Role Key。

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
- 小程序端不得保存任何支付私钥或 火山方舟 API Key
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
- `ALIPAY_RETURN_URL`（可选，当前建议留空）
- `ALIPAY_GATEWAY`

notify_url：

```text
https://api.your-domain.com/api/pay-alipay-notify
```

return_url 当前建议留空：

```text
ALIPAY_RETURN_URL=
```

原因：Web 支付页会在新标签页打开。用户付款成功后关闭支付宝页面，回到原钱包充值页即可看到支付状态刷新。这样可以避免支付宝回跳到另一个域名或新页面后登录态不一致。

第一版优先支持 Web 支付链接；`h5`、`app`、小程序已预留。

支付宝密钥填写说明：

- `ALIPAY_PRIVATE_KEY` 填应用私钥，只能放在 Vercel 服务端环境变量。
- `ALIPAY_PUBLIC_KEY` 填支付宝公钥，不是应用公钥。
- 私钥和公钥可以保留 `-----BEGIN ...-----` 头尾；如果从支付宝工具复制的是纯 key body，服务端会自动补齐 PEM 格式。
- 配置完成并重新部署后，可访问 `/api/payment-debug` 检查 `alipay.configured` 是否为 `true`，该接口不会返回密钥内容。

## 10. 充值订单和回调入账流程

1. 客户端调用 `/api/recharge-create`。
2. 服务端校验登录态和金额。
3. 服务端创建 `recharge_orders`，状态为 `pending`。
4. 服务端调用微信或支付宝下单。
5. 客户端展示微信扫码链接或支付宝支付链接。
6. 支付平台异步回调 `/api/pay-wechat-notify` 或 `/api/pay-alipay-notify`。
7. 服务端保存回调日志。
8. 服务端验签、校验订单号、校验金额。
9. 数据库事务中更新订单为 `paid`、增加钱包余额、写入 `wallet_transactions`。
10. 重复回调通过订单状态和流水唯一约束保证不重复入账。

## 11. AI 扣费和失败退款流程

1. 客户端调用 `/api/ai-report-generate`。
2. 服务端根据 `productId` 查价格，不能相信前端价格。
3. 余额不足直接返回，不调用 豆包。
4. 余额足够时，数据库事务中扣钱包余额、写 `ai_debit` 流水、创建 `ai_report_orders`。
5. 事务提交后调用 豆包。
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
- AI 余额不足不调用 豆包。
- AI 成功扣费并保存报告。
- AI 调用失败自动退款。
- 报告复看不重复扣费。
- 页面不出现会员等级、VIP、积分、权益文案。
- Web / App / 小程序均调用同一套 API。

## 13. 用户数据同步与个人数据管理

重新执行最新版 `supabase/schema.sql` 后，登录用户的历史记录和命盘档案会采用本机优先、云端同步策略。新增表、API、注销保护和人工测试步骤见 `docs/USER_DATA_AND_GROWTH_CAPABILITIES.md`。

部署顺序：

1. 在 Supabase SQL Editor 执行最新版 `supabase/schema.sql`。
2. 确认四张新增表和 `delete_account_data` 函数存在。
3. 部署 Vercel。
4. 使用两个账号验证记录隔离和跨设备恢复。

## 豆包接入与统一解析价格

当前付费报告改用火山方舟官方 Responses 接口，不再调用 DeepSeek，也不自动回退到旧模型。本机已完成最小真实请求验证；公网完整报告、扣费及退款仍需部署后联调，不能把连通性测试等同于上线验收。

### 服务端配置

仅在 Vercel 的目标环境配置，不能写入 Flutter、dart-define 或公开文件：

```dotenv
ARK_API_KEY=在Vercel填写自己的方舟密钥
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
ARK_MODEL_ID=doubao-seed-2-1-pro-260915
ARK_TIMEOUT_MS=270000
```

模型默认使用已实测的完整版本 ID `doubao-seed-2-1-pro-260915`，不使用旧简称 `doubao-seed-2.1-pro`。如果 Vercel 已配置旧模型名称，必须修改环境变量并重新部署；环境变量会覆盖代码默认值。密钥使用方舟 API Key，不是 Access Key ID / Secret 两个值拼接。地址限定为上述官方北京 API，以防密钥误发至其他站点；ARK_BASE_URL 不附加 /responses，程序自行拼接。旧 DEEPSEEK_API_KEY 不再用于当前付费报告链路。

请求发送到 `/responses`，使用 `model` 和 `input`，只发送一条 user 消息（`input_text`），并设置 `store: false`（不启用方舟响应对象存储，不代表关闭供应商全部服务日志）。请求只包含功能名称、用户事项、原始卦象或命盘资料及必要时间，不规定等级、篇幅、结论或输出格式。不沿用 DeepSeek 的 temperature、max_tokens，也不擅自关闭深度思考，输出上限使用模型默认值。

仅接收已完成响应中的 assistant message / output_text 正文，不将 reasoning 作为报告。不完整、拒绝、空正文、失败或超时均进入现有失败退款流程。Responses 的 input_tokens / output_tokens 转换为现有日志接口的 prompt_tokens / completion_tokens，不改钱包数据库 RPC。字段结构参考 [火山引擎官方 SDK](https://github.com/volcengine/ark-runtime-python)。

`server/promptLoader.js` 返回空系统提示词，不再读取旧文件或 `AI_REPORT_SYSTEM_PROMPT` 环境变量。Vercel 上的旧覆盖值可以删除；即使保留，也不会影响当前付费报告请求。请求资料由 `lib/features/ai_reports/ai_report_prompt_builder.dart` 组装。模型正文直接保存和展示，仅由程序添加已约定的民俗娱乐提示与 AI 内容标识，不进行二次模型改写。

### 价格与历史兼容

- 所有新 AI 报告统一 500 分（5 元），由 server/productCatalog.js 定价。
- 每个功能仅保留一个“¥5 AI 解析”选项，不显示等级或字数。内部沿用既有 productId，以兼容服务端和历史数据；ID 中的旧数字不代表现价。
- 已购买的旧简析、基础、深度等报告全部保留免费复看、复制和分享。已有有效报告时不再提供同一结果的付费生成按钮；旧失败报告仍可通过单一入口重试。
- 请求带 expectedPriceCents，仅用于核对客户端已展示的价格，绝不以客户端报价扣款。
- 未发送价格确认或仍发送旧价格的网页/APK 返回 409，提示刷新/更新，不扣费。
- 旧订单实付金额、钱包余额、退款金额不重写，历史报告复看不收费。退款仍按原订单实付金额执行。充值金额档位不变。
- 空响应、被截断的报告、调用失败或超时进入已有失败退款链路。保留模型原文，不进行第二次模型改写；民俗提示在保存正文前添加，因此复看、分享、HTML 导出均随正文携带。

### 数据库日志

已有数据库单独执行 `supabase/migrations/20260921_ark_ai_call_provider.sql`。新建库执行 schema.sql 已包含该变更。不需要重建钱包、重跑充值脚本或改动历史记录。

该迁移只用触发器把新豆包/ep-模型调用日志标记为 volcengine，不更改任何扣费、完成、退款 RPC 的签名或逻辑。历史 DeepSeek 日志保持原样。

### 时间与耗时

- 新起卦结果额外保存 UTC 时间，AI 请求附上换算后的完整北京时间，不使用报告请求时间替代。
- 高岛易断在成卦时固定时间，页面重建不重取当前时间；梅花易数保存历史时复用已生成结果。命盘请求保留出生资料，不把报告生成时间当作起卦时间。
- 新历史记录保留六爻结构区块；旧记录没有的内容不伪造，旧时间缺少时区时明确注明不足。排盘/起卦算法不变。
- AI 等待时间单独延长到 330 秒；服务端模型请求最多 270 秒，为保存或退款留出时间，其他钱包请求超时不变。
- vercel.json 设置函数最长 300 秒，部署时需要核实已开启 Fluid Compute 且项目支持该上限，参见 [Vercel 官方时长说明](https://vercel.com/docs/functions/configuring-functions/duration)。
- 这仍是同步请求，不是后台任务。平台提前终止、断网或数据库退款失败仍需核对订单和流水；不能仅凭前端超时认定已退款。模型自然输出的长报告能否在上限内完成需联调验证。

### 联调与测试

2026-09-22 本机验证：`npm run check:api` 与 `npm run test:server` 通过。覆盖 Responses 正文读取、token 记录、统一500分、旧价格拦截、余额不足不调用模型，以及无效/不完整响应触发退款。自动测试不访问生产数据库。

同日本机使用 `.env.local` 当前密钥，通过项目 `callDoubao` 真实请求 `/responses`：HTTP 200，模型 `doubao-seed-2-1-pro-260915`，正文“连接成功。”，耗时约7.9秒。该请求未操作用户钱包，仅验证密钥、模型、请求格式及正文解析。

本次修改复测：`flutter test test/features/ai_reports test/features/ask_guidance test/widget_test.dart --no-pub` 共54项通过，涵盖单一5元选项、去除等级和字数文案、精简请求、原始时间、页面重建时间不变、空结果重试、问题带入，以及旧档位报告免费复看、复制和分享。

2026-09-23 本次修改的正式 Web 构建通过：`flutter build web --release --no-pub --web-renderer html --pwa-strategy=none --dart-define=GUOXUE_API_BASE_URL=https://guoxuewanbao.cn`。构建有现存 Cupertino 字体提示，未阻断构建。本轮未进行生产钱包真实扣费测试，未重新打包 APK。旧 APK 请求旧价格时会被拦截且不扣费，需更新 APK 或使用部署后刷新的 Web 页面。

部署后还需用测试账号联调真实完整报告；基础连通性不能证明长报告耗时及线上退款一定正常。环境变量必须在 Production 配置后重新部署，不能仅修改本机 `.env.local`。

人工重点：问事/每日一卦/命盘均显示5元，扣款500分，失败退回500分；历史报告复看不扣费；旧客户端先要求刷新；方舟日志显示预期模型；报告包含正确原始时间、民俗提示与有效正文。真实请求会使用方舟额度，联调前另行确认。

### Android 安装包更新（2026-09-23）

- 官网下载页：`https://guoxuewanbao.cn/download`；固定文件：`/downloads/guoxuewanbao-latest.apk`。
- 本次版本：`1.0.0+2`，包名 `com.guoxue.wanbaoxia`，兼容 Android 5.0 及以上，包含 arm64-v8a、armeabi-v7a、x86_64。
- 构建命令：`flutter build apk --release --no-pub --dart-define=GUOXUE_API_BASE_URL=https://guoxuewanbao.cn`。API 地址指向官网；密钥仍只保留在服务端。
- 安装包 23,973,877 字节（约 22.9 MiB）；SHA-256：`794b6f04e06de7a78438fa45000dc512fdc0c505ca8c36901e65734beba86550`。
- 沿用原 Android 测试签名，新旧证书 SHA-256 一致，且签名校验通过。未切换正式应用市场签名；请直接覆盖安装，不要先卸载，以免清除本机资料。
- 包含单一5元豆包解析、原始起卦时间和旧报告免费复看。App 内复制的安装包链接改为官网 HTTPS 地址。
- 本次下载链接及 AI 解析相关回归测试共54项通过；APK 完整性和新旧签名一致性已校验。
- 构建成功，但输出了现有 Kotlin 元数据兼容性及 Cupertino 字体提示；尚未在实体手机完成安装、登录、支付和解析通测，应在发布到应用市场前解决工具链提示并完成实机验证。
