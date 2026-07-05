# Gmail 发信冒烟测试（P5-T20）

> 验证真实 Gmail API：**自发自收** + **CC** + **富文本 HTML**（`multipart/alternative`）回读正确。  
> 不在 PR 必跑 CI 中执行（避免 quota 消耗），见 [`specs/06-testing.md` §2.3](../specs/06-testing.md)。

---

## 前置条件

1. GCP 项目已启用 **Gmail API**
2. OAuth Client 已配置 scope：`gmail.send` + `gmail.readonly`
3. 测试账号已完成授权（本地 dev 登录一次，或 OAuth Playground 获取 access token）

---

## 方式 A — 自动化冒烟（推荐）

### 1. 获取 Access Token

**选项 1：OAuth 2.0 Playground**

1. 打开 [Google OAuth 2.0 Playground](https://developers.google.com/oauthplayground/)
2. 右上角齿轮 → 勾选「Use your own OAuth credentials」，填入 `GOOGLE_OAUTH_CLIENT_ID` / `SECRET`
3. 左侧选择 Gmail API v1 → `https://mail.google.com/`（或 `gmail.send` + `gmail.readonly`）
4. Authorize → Exchange authorization code for tokens → 复制 **Access token**（约 1 小时有效）

**选项 2：本地 dev 登录后从日志/调试获取**（需后端已跑通 OAuth）

### 2. 导出环境变量

```bash
export GMAIL_SMOKE_ACCESS_TOKEN="ya29...."
export GMAIL_SMOKE_TO="your-test@gmail.com"
# 可选；缺省则 CC = TO（自抄送）
export GMAIL_SMOKE_CC="cc-recipient@gmail.com"
```

### 3. 运行测试

```bash
cd kol-mail-desk-v2-backend
mvn -pl maildesk-integration -Dtest=GmailSendSmokeTest test
```

**期望结果：**

- `GmailSendSmokeTest.sendSelfReceive_withCcAndRichText_readbackMatches` **PASSED**
- 邮箱收到主题 `[MailDesk Smoke] ...` 的邮件
- To / Cc 均收到（若 CC 为独立地址）
- 正文 HTML 含加粗与列表

**未配置 env 时：** 测试类被 `@EnabledIf` 静默跳过，不影响 `mvn verify`。

---

## 方式 B — 工作台 UI 手工冒烟

1. 启动后端 + 前端（见 [`SETUP.md`](../specs/SETUP.md)）
2. Google 登录并完成 Gmail 授权
3. 工作台选择一位达人 → 展开「撰写回复」
4. 填写：
   - **CC**：自己的备用邮箱或同一 Gmail（自抄送）
   - **富文本**：加粗、列表、链接各测一项
   - 勾选「已人工审核」→ 发送
5. 验收：
   - [ ] Gmail 收件箱 To 收到
   - [ ] CC 邮箱收到
   - [ ] HTML 格式正确（非纯文本 fallback）
   - [ ] 工作台 outbound 邮件时间线出现新记录
   - [ ] `actions` 表有 `email_sent` 审计行

---

## 方式 C — 批量跟进冒烟（可选）

1. 工作台筛选「需我回复」列表
2. 顶栏「批量跟进」→ 确认 CC → 发送（≤25 封）
3. 验收：进度反馈逐条显示成功/失败；成功项 `last_outbound_at` 更新

---

## 故障排查

| 现象 | 可能原因 |
|------|----------|
| `401` / token 无效 | Access token 过期，重新获取 |
| `403 accessNotConfigured` | GCP 未启用 Gmail API |
| `not_configured`（API 响应） | 后端缺 refresh token 或 OAuth client 未配置 |
| HTML 回读为空 | Gmail 延迟；重试 `getMessage` 或查 Sent 文件夹 |
| CC 未收到 | CC 地址与 To 相同且 Gmail 合并显示；改用独立 CC 邮箱验证 |

---

## 关联 ticket

- **P5-T20** · Phase 5 验收最后一项
- Feature parity：**F-WRITE-07**（CC）、**F-WRITE-08**（富文本 multipart）
