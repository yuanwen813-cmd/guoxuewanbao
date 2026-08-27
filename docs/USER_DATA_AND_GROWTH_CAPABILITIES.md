# 用户数据与增长能力部署说明

本轮只补充用户数据可靠性、AI 反馈、运营统计和 Web 安装更新体验，未修改起卦、排盘、支付回调、收费价格或 AI 提示词。

## 已增加的能力

1. 登录用户的历史记录和命盘档案采用“本机优先、云端同步”。
2. 未登录数据仍保存在当前设备，不会自动归入其他账号。
3. 旧版全局命盘档案不会静默绑定账号，用户可在命盘档案页主动导入。
4. “设置 - 我的数据”支持个人数据导出和账号注销。
5. 已生成的 AI 报告支持“有帮助 / 没帮助”反馈。
6. 后台概览增加云端历史数、命盘档案数、AI 反馈和用户来源。
7. Web 支持浏览器安装提示和发现新版本后的更新提示。
8. 带 `utm_source`、`utm_medium`、`utm_campaign` 或 `ref` 的访问链接会在登录后记录来源。

## 上线前数据库操作

在 Supabase SQL Editor 中重新执行 `supabase/schema.sql`。脚本使用 `if not exists` 和 `create or replace`，可在现有项目上增量执行。

新增表：

- `user_history_records`
- `birth_profiles`
- `ai_report_feedback`
- `user_attributions`

新增函数：

- `delete_account_data(uuid)`
- 更新后的 `admin_dashboard_summary()`

这些表均开启 RLS，前端角色无直接读写权限；只有 Vercel 服务端使用 Service Role Key 访问。

## 新增 API

- `GET /api/user-data`：读取当前用户云端历史和命盘档案。
- `POST /api/user-data`：同步新增、修改或删除的数据。
- `GET /api/account-export`：导出当前用户个人数据。
- `POST /api/account-delete`：注销账号，需提交 `确认注销`。
- `POST /api/ai-report-feedback`：提交 AI 报告反馈。
- `POST /api/attribution-record`：记录登录用户访问来源。

所有接口必须携带当前用户的 Authorization Token，客户端不能指定其他用户 ID。

## 账号注销保护

账号注销前必须满足：

1. 钱包余额为 0。
2. 没有待支付充值订单。

注销会删除历史记录、命盘档案、AI 反馈和来源记录，并清除 AI 报告中的个人输入与结果内容。钱包流水、充值订单和必要财务记录继续保留，但账号手机号、昵称和头像会清除，账号状态改为停用。

## 人工测试

1. 使用账号 A 登录，新增历史和命盘档案。
2. 换一台浏览器或清理本地缓存，重新登录账号 A，确认记录恢复。
3. 登录账号 B，确认看不到账号 A 的历史和命盘档案。
4. 在旧版存在本机命盘档案的设备上，确认页面出现“导入本机旧档案”，且不会自动绑定。
5. 生成 AI 报告，提交“有帮助 / 没帮助”，后台概览数字应变化。
6. 用 `?utm_source=test&utm_medium=manual&utm_campaign=launch` 打开网站并登录，后台应出现来源统计。
7. 在支持 PWA 的 Chrome/Edge 中验证安装提示。
8. 部署新版本后重新打开旧页面，确认出现更新提示，点击后载入新版本。
9. 导出个人数据，确认包含账号、钱包、订单、AI 报告、历史和命盘档案。
10. 有余额或待支付订单时尝试注销，应被阻止；满足条件后才能注销。

## 发布注意

先执行数据库脚本，再部署 Vercel。若先部署前端和 API 而未建新表，旧业务仍可使用，但云同步、反馈、来源统计和个人数据管理会提示服务端失败。
