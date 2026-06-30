# v3.3 功能对照清单（可追踪 Checklist）

> 来源：Lovart Mail Desk 使用说明书（v3.3）。新系统下线旧系统前，下表每一项必须从 `[ ]` 翻成 `[✅]` 或 `[⚠️]`（带原因）。
> 状态符号：`[ ]` 未开始 / `[🔄]` 进行中 / `[✅]` 完成 / `[⚠️]` 完成但有缺陷 / `[🚫]` 决定不做（必须写原因）。
>
> **每条功能格式**：
>
> ```text
> - [状态] **功能名**
>   - Phase / Ticket / Feature ID
>   - 后端实现 / 前端实现 / E2E case
>   - 验收点
> ```
>
> Feature ID 形如 `F-AUTH-01`，跨文档稳定引用。

---

## 1. 登录与入职（说明书 §登录流程、§2）

### F-AUTH-01 Google OAuth 登录

- [ ] **Google OAuth 登录，授权 Gmail scope（读 + 发送）**
  - Phase: P1 | Ticket: P1-T04 | 后端: `maildesk-api/.../auth/GoogleOAuth2Controller.java`
  - 前端: P1-T15 ✅ `app/login/page.tsx` | E2E: P1-T17 ✅ `e2e/smoke/routes.spec.ts` @smoke（mock API）
  - 验收: scope 含 `gmail.readonly` + `gmail.send`；refresh_token AES 加密入 `integration_credentials`

### F-AUTH-02 同意页文案

- [ ] **OAuth 同意页 / 登录页提示「邮箱权限必须勾选」**
  - Phase: P1 | Ticket: P1-T04 | 后端: GCP OAuth 同意屏 + 后端登录引导
  - 前端: `app/login/page.tsx` 文案 + 截图占位
  - 验收: 登录页显著文案 + Google 同意屏 brand info 配置

### F-AUTH-03 测试用户白名单

- [ ] **测试用户白名单（GCP OAuth Test users）**
  - Phase: P1 | Ticket: P1-T04（基础设施部分）
  - 验收: 在 GCP Console → OAuth consent → Test users 配置完成；过渡到 published 之前未在白名单的用户走不通登录

### F-AUTH-04 首次登录资料完善

- [ ] **首次登录跳入资料页：显示名、角色、mentor、飞书运营名**
  - Phase: P1 | Ticket: P1-T05（后端 ✅）+ P1-T15（前端 ✅ `/onboarding`）| 后端: `PATCH /api/v1/team/profile`
  - 前端: `app/profile/page.tsx` 或登录后引导弹窗 | E2E: `e2e/auth/first-login.spec.ts`
  - 验收: 必填校验生效；未填完不可访问工作台主功能

### F-AUTH-05 飞书运营名归属

- [ ] **保存飞书运营名后自动归属匹配的 KOL（无主才认领）**
  - Phase: P2 | Ticket: P2-T04 | 后端: `TeamApplicationService.assignKolsByOperatorName`
  - 验收: 已有 owner 的 KOL 不被覆盖；只领无主 KOL；写 audit log

### F-AUTH-06 历史同步引导

- [ ] **首次登录引导点「历史同步」拉取最近 1 年邮件**
  - Phase: P3 | Ticket: P3-T08 | 前端引导 UI（旧 `HistorySyncBanner` 复用）
  - 验收: 完成历史同步后 banner 自动消失

---

## 2. 工作台（§3）

### 2.1 左侧导航与侧栏统计（§3.1）

### F-WB-NAV-01 左侧导航 5 项

- [ ] **导航：工作台 / 团队看板 / 团队成员 / 邮件模板 / 定时邮件**
  - Phase: P1 | Ticket: P1-T13, P1-T15（前端 ✅）| 前端: `components/shell/AppNav.tsx` + 6 路由页
  - 验收: 5 个导航可点击，路由正确，未授权页面 redirect 到登录

### F-WB-SIDE-01 ~ 04 侧栏统计

- [ ] **侧栏统计：需我回复 / 高优先级 / 团队池 / 总达人**
  - Phase: P1 | Ticket: P1-T06（后端 ✅）+ P1-T15（前端 ✅）| 后端: `GET /api/v1/workbench` → `sidebarStats`
  - 前端: `components/WorkbenchSidebar.tsx`
  - 验收（各项口径）:
    - 需我回复：最新邮件 inbound + 未手动标记「无需回复」
    - 高优先级：AI 或规则判断的 inbound 高优先级（P4 接入前用规则 fallback）
    - 团队池：`status IN ('unassigned', 'orphaned')`
    - 总达人：当前视图（我的/团队池/全部）下可见数

### 2.2 顶部搜索与同步按钮（§3.2）

### F-WB-SEARCH-01 全局搜索

- [ ] **搜索框支持 Ctrl+K 聚焦**
  - Phase: P1 | Ticket: P1-T13（组件迁入）| 前端: `components/SearchPalette.tsx`
  - 验收: macOS Cmd+K 也工作；ESC 关闭

- [ ] **搜索匹配：达人名、邮箱、邮件主题、AI 摘要**
  - Phase: P1（基础）/ P7（OpenSearch 升级）| Ticket: P1-T06（后端 ✅，workbench `q` 参数）+ P7-T06
  - 后端: `GET /api/v1/workbench?q=...` ILIKE 多列；P7 换 OpenSearch
  - 验收: 200ms 内返回 ≤30 条匹配；高亮关键词

### F-WB-SYNC-01 同步 Gmail 按钮

- [ ] **「同步 Gmail」按钮：增量 / 历史两种模式**
  - Phase: P3 | Ticket: P3-T08 | 后端: `POST /api/v1/sync/gmail?mode=incremental|history`
  - 前端: `components/GmailSyncButton.tsx`（旧仓库迁入并改 API）
  - 验收: 增量模式 < 30s；历史模式分页且能续传；非阻塞 UI

### F-WB-SYNC-02 批量跟进按钮

- [ ] **「批量跟进」按钮：多选达人 → 选模板 → 发送**
  - Phase: P5 | Ticket: P5-T07, P5-T18 | 后端: `POST /api/v1/gmail/batch-send`
  - 前端: `components/BatchFollowupButton.tsx`
  - 验收: 串行限流（每秒 ≤2 封）；每封独立记录；任一封失败不影响其他

### F-WB-SYNC-03 重新授权 Gmail

- [ ] **「重新授权 Gmail」按钮：Token 过期/失效时出现**
  - Phase: P3 | Ticket: P3-T04 | 后端: `GET /api/v1/auth/gmail/reauthorize`
  - 前端: 顶栏检测 `integration_credentials.status='expired'` 时显示按钮
  - 验收: 完成授权后自动恢复同步；新 refresh_token 替换旧加密载荷

### F-WB-SYNC-04 同步非阻塞

- [ ] **同步任务边同步边操作 UI；完成后自动刷新**
  - Phase: P3 | Ticket: P3-T05, P3-T06 | 前端: 客户端循环 + 渐进刷新
  - 验收: 同步过程中达人列表可滚动 / 详情可打开

### 2.3 达人列表（§3.3）

### F-WB-LIST-01 三种范围

- [ ] **范围：我的 / 团队池 / 全部**
  - Phase: P1 | Ticket: P1-T06（后端 ✅）+ P1-T15（前端 ✅）| 后端: `GET /api/v1/workbench?view=mine|pool|all`
  - 验收: 我的 = `owner_user_id = currentUser`；团队池 = `status IN ('unassigned','orphaned')`；全部 = 当前租户全量

### F-WB-LIST-02 每行字段

- [ ] **每行展示：达人名 / 最近邮件主题 / AI 摘要 / 阶段标签 / 负责人 / 工作流标签 / 优先级标签**
  - Phase: P1（基础）+ P4（AI 摘要）| Ticket: P1-T06, P4-T03
  - 前端: `components/KolListItem.tsx`
  - 验收: 7 个字段渲染齐全；AI 失败时显示"AI 分类失败"占位

### F-WB-LIST-03 10 阶段标签

- [ ] **阶段标签使用 v3.3 §6 的 10 阶段映射**
  - Phase: P2 | Ticket: P2-T02 | 后端: `kol_stage` ENUM + 映射表
  - 验收: 10 阶段全部覆盖；映射 SQL 验收脚本通过

### 2.4 达人详情卡片（§3.4）

### F-WB-DETAIL-01 基础信息

- [ ] **达人名、邮箱、来源、平台、类型、负责人、报价、主页链接、合作状态、备注**
  - Phase: P1 | Ticket: P1-T06（后端 ✅）+ P1-T15（前端 ✅）| 后端: `GET /api/v1/kols/{kolId}` | 前端: 工作台详情 pane
  - 验收: 字段对照 v3.3 §3.4 一一齐全；报价类型为 `BigDecimal`

### F-WB-DETAIL-02 改名

- [ ] **「改名」按钮：仅改工作台显示名，不写回飞书**
  - Phase: P5 | Ticket: P5-T01, P5-T15 | 后端: `PATCH /api/v1/kols/{id}/display-name`
  - 验收: `kol.feishu_name` 不变，仅更新 `kol.display_name`；飞书 API 无 PUT/POST 调用

### F-WB-DETAIL-03 人工校准阶段

- [ ] **「人工校准阶段」：覆盖飞书阶段**
  - Phase: P5 | Ticket: P5-T02, P5-T15 | 后端: `PATCH /api/v1/kols/{id}/stage-override`
  - 验收: `kol.stage_override` 写入；下次飞书同步不覆盖；UI 显示「(校准)」标记

### F-WB-DETAIL-04 打开主页

- [ ] **「打开主页」按钮：跳外部链接核验**
  - Phase: P1 | Ticket: P1-T13 | 前端: 复用旧组件
  - 验收: `target=_blank rel=noopener noreferrer`；空链接禁用按钮

### 2.5 邮件阅读区（§3.5）

### F-WB-EMAIL-01 HTML 渲染

- [ ] **HTML 邮件渲染（链接可点 / 图片显示 / 列表加粗保留）**
  - Phase: P1 | Ticket: P1-T13 | 前端: 复用旧 `EmailBody.tsx`
  - 验收: 渲染正确；用 `isomorphic-dompurify` 净化避免 XSS

### F-WB-EMAIL-02 历史回复折叠

- [ ] **历史回复折叠（「显示历史回复」）**
  - Phase: P1 | Ticket: P1-T13 | 前端: 复用旧逻辑
  - 验收: 长邮件链不撑满阅读区；折叠/展开切换正常

### F-WB-EMAIL-03 DOMPurify 净化

- [ ] **邮件正文用 `isomorphic-dompurify` 净化**
  - Phase: P1 | Ticket: P1-T13 | 前端: 复用旧实现
  - 验收: XSS payload（`<script>`, `onerror=`）被剥离

### 2.6 处理状态按钮（§3.6）

### F-WB-STATE-01 无需回复

- [ ] **「标记无需回复」**
  - Phase: P5 | Ticket: P5-T03, P5-T15 | 后端: `POST /api/v1/kols/{id}/reply-resolved`
  - 验收: `kol.reply_resolved=true`；该 KOL 不再计入「需我回复」

### F-WB-STATE-02 取消无需回复

- [ ] **「取消无需回复」（恢复自动判断，不强制变回需回复）**
  - Phase: P5 | Ticket: P5-T03 | 后端: `DELETE /api/v1/kols/{id}/reply-resolved`
  - 验收: 仅清除手动覆盖；最终是否需回复由规则计算

### F-WB-STATE-03 标记已读/未读

- [ ] **「标记已读 / 未读」（不等于已回复）**
  - Phase: P5 | Ticket: P5-T04, P5-T16 | 后端: `PATCH /api/v1/emails/{id}/read`
  - 验收: 已读状态独立于 reply_resolved；自动已读策略可配置

### F-WB-STATE-04 新邮件清 reply_resolved

- [ ] **新 inbound 邮件自动清除 `reply_resolved`**
  - Phase: P3 | Ticket: P3-T07 | 后端: `persistGmailSync` 内
  - 验收: 该 KOL 收到新邮件 → `reply_resolved` 自动 false

---

## 3. 撰写回复与富文本编辑器（§4）

### F-WRITE-01 ~ 06 编辑器能力

- [ ] **富文本编辑器（TipTap）：加粗 / 斜体 / 下划线 / 字体颜色 / 无序列表 / 有序列表 / 插入链接**
  - Phase: P5 | Ticket: P5-T14 | 前端: 复用旧 `DraftSendPanel` + TipTap config
  - 验收: 7 项工具按钮全部生效；导出 HTML 干净（无 TipTap 私有 class 泄漏）

### F-WRITE-07 CC 抄送

- [ ] **CC 抄送字段**
  - Phase: P5 | Ticket: P5-T06, P5-T14 | 后端: `emails.cc_emails TEXT[]`
  - 验收: 真实 Gmail 冒烟 To + Cc 均收到；Gmail messageId 回读

### F-WRITE-08 富文本发送

- [ ] **富文本 HTML 发送（`multipart/alternative`）**
  - Phase: P5 | Ticket: P5-T06 | 后端: `GmailSendService.sendMultipart`
  - 验收: Content-Type 头正确；纯文本和 HTML 部分都有

### F-WRITE-09 人工确认

- [ ] **发送前必须人工确认（不自动发 AI 草稿）**
  - Phase: P5（覆盖范围）+ P4（AI 不触发 send）
  - 验收: AI 调用结果只写 draft 字段；任何场景 send 都需用户点击

### F-WRITE-10 发送成功后副作用

- [ ] **发送成功后：Gmail 真发 + outbound 入 emails + KOL.last_outbound_at 更新 + 模板 used_count++ + 写审计 log**
  - Phase: P5 | Ticket: P5-T06, P5-T08, P5-T13 | 后端: `GmailSendApplicationService`
  - 验收: 5 个副作用全部触发；任一失败回滚或补偿（事务边界明确）

---

## 4. 团队看板（§5）

### F-BOARD-KPI 顶部 KPI（§5.1）

- [ ] **总达人（当前时间窗内）**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）| 后端: `GET /api/v1/board?window=...`
- [ ] **待回复 / 停滞数**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）
- [ ] **未读邮件（inbound + is_read=false，当前时间窗）**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）
- [ ] **进入合作数 / 转化率（confirmed 及之后阶段达人数 + 比例）**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）
  - 验收: 4 项 KPI 数字与旧系统对账（允许 ±1 容差）

### F-BOARD-WINDOW 时间窗（§5.2）

- [ ] **6 个时间窗：全部 / 本周 / 本月 / 最近 30 天 / 指定月份 yyyy-MM**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）| 后端: `BoardWindow` 解析 `window` 参数
- [ ] **时间窗基于 `feishu_outreach_at`**
- [ ] **无日期的达人只出现在「全部时间」**
  - 验收: 月份切换无数据时 UI 提示「该月无飞书登记记录」

### F-BOARD-PIPELINE 漏斗与阶段分布（§5.3）

- [ ] **「累计漏斗」模式（本阶段及以后累计人数）**
  - Phase: P1 | Ticket: P1-T07（后端 ✅）| 后端: `StageCatalog` 累计计数
- [ ] **「阶段分布」模式（当前正处于该阶段人数）**
- [ ] **两种模式 UI 切换 + 副标题动态变化**
  - 前端: `components/PipelinePanel.tsx`
  - 验收: 切换无重新拉数；漏斗从触达到付款单调递减

### F-BOARD-RATIO 比率指标（§5.4）

- [ ] **达人回复率（触达 → 沟通/议价及之后）**
- [ ] **转化率（触达 → 付款）**
- [ ] **回复率/转化率仅在漏斗模式显示**
  - Phase: P1 | Ticket: P1-T07
  - 验收: 比率口径与旧系统逐字一致；E2E 截图回归

---

## 5. 阶段映射（§6）

### F-STAGE-01 完整映射

- [ ] **v3.3 §6 飞书状态 → 工作台阶段 10 阶段映射表**
  - Phase: P2 | Ticket: P2-T02 | 后端: `FeishuStageMapper`
  - 验收: 飞书所有出现过的状态都有映射；未知状态 fallback `unknown` + 告警日志

### F-STAGE-02 飞书是唯一来源

- [ ] **阶段以飞书为来源，AI 不决定阶段**
  - Phase: P4 | Ticket: P4-T03 | 后端: AI Prompt 明确不输出 stage
  - 验收: AI 返回 JSON schema 无 stage 字段

### F-STAGE-03 人工可校准

- [ ] **工作台可人工校准阶段**（详见 F-WB-DETAIL-03）

### F-STAGE-04 飞书严格只读

- [ ] **飞书数据严格只读，不写回飞书**
  - Phase: P2 | Ticket: P2-T07 | 后端: ArchUnit 守护
  - 验收: ArchUnit 测试通过；代码评审禁止引入飞书写 API

---

## 6. 团队成员（§7）

### F-TEAM-LIST 成员列表（§7.1）

- [ ] **显示：姓名 / 邮箱 / 状态 / 角色 / mentor / 飞书运营名**
  - Phase: P1 | Ticket: P1-T08（后端 ✅）| 后端: `GET /api/v1/team/members`
- [ ] **关键指标：在跟达人数 / 已成交数 / 停滞风险**
  - Phase: P1 | Ticket: P1-T08（后端 ✅）
  - 验收: 离职成员仍可见但标灰

### F-TEAM-OP 操作（§7.2）

- [ ] **保存设置（角色 / mentor / 飞书运营名）**
  - Phase: P5 | Ticket: P5-T10
- [ ] **飞书运营名保存后自动批量归属**（详见 F-AUTH-05）
- [ ] **「标记离职」（Leader 权限）**
  - Phase: P5 | Ticket: P5-T11 | 后端: `POST /api/v1/team/members/{id}/offboard`
- [ ] **离职后名下达人进入团队池（status → orphaned）**
  - Phase: P5 | Ticket: P5-T11
- [ ] **「查看团队池」（Leader 权限）**
  - Phase: P1（GET）+ P5（分配按钮）| Ticket: P1-T08, P5-T12
- [ ] **Leader 在团队池中分配达人给指定成员**
  - Phase: P5 | Ticket: P5-T12 | 后端: `POST /api/v1/team/pool/assign`
  - 验收: 历史邮件记录保留；写审计 log

---

## 7. 邮件模板（§8）

### F-TPL-01 私有模板库

- [ ] **模板库私有，每个成员只看自己**
  - Phase: P1（GET 后端 ✅）+ P5（CRUD）| Ticket: P1-T09, P5-T09 | 后端: `GET /api/v1/templates`
  - 验收: 跨用户 GET 不可见；尝试访问他人模板 403

### F-TPL-02 必填字段

- [ ] **新建模板必填：名称 / 场景 / 主题 / 正文**
  - Phase: P5 | Ticket: P5-T09 | 后端: Jakarta Validation
  - 验收: 任一字段为空 400

### F-TPL-03 变量

- [ ] **正文支持变量（如 `{{creator_name}}`）**
  - Phase: P5 | Ticket: P5-T09 | 后端: `TemplateRenderService.render`
  - 验收: 至少支持 `creator_name` / `platform` / `quote` / `homepage_url`

### F-TPL-04 模板 CRUD

- [ ] **模板增 / 删 / 改 / 查**
  - Phase: P5 | Ticket: P5-T09, P5-T17

### F-TPL-05 使用模板

- [ ] **撰写邮件 / 批量跟进时可选模板**
  - Phase: P5 | Ticket: P5-T14, P5-T18

### F-TPL-06 used_count

- [ ] **使用模板后使用次数 +1**
  - Phase: P5 | Ticket: P5-T08
  - 验收: 仅在 send 成功后 +1；预览/草稿不 +1

---

## 8. 定时邮件（§9）

### F-SCHED-01 保存计划

- [ ] **草稿面板可保存定时计划**
  - Phase: P6 | Ticket: P6-T02 | 前端: `DraftSendPanel` 增加时间选择器

### F-SCHED-02 列表字段

- [ ] **列表显示：达人 / 计划发送时间 / 主题 / 状态 / 是否含 CC / 是否富文本**
  - Phase: P1（GET 后端 ✅）+ P6（状态机）| Ticket: P1-T10, P6-T01 | 后端: `GET /api/v1/scheduled-emails`
  - 验收: 6 个字段齐全；状态符合 P6 状态机

### F-SCHED-03 5 个状态

- [ ] **状态：scheduled / processing / sent / failed / cancelled**
  - Phase: P6 | Ticket: P6-T01
  - 验收: 状态转移合法（scheduled → processing → sent/failed）；cancelled 仅在 scheduled 状态可行

### F-SCHED-04 发送前取消

- [ ] **发送前可取消**
  - Phase: P6 | Ticket: P6-T02 | 后端: `DELETE /api/v1/scheduled-emails/{id}`
  - 验收: processing 后不可取消

### F-SCHED-05 原子认领

- [ ] **Worker 到点原子认领（防重复发送）**
  - Phase: P6 | Ticket: P6-T03 | 后端: `UPDATE ... WHERE status='scheduled' AND scheduled_at<=now() RETURNING ...`
  - 验收: 多 Worker 并发场景一封邮件最多被一个 Worker 取走

### F-SCHED-06 重试

- [ ] **失败最多重试 3 次**
  - Phase: P6 | Ticket: P6-T04
  - 验收: 指数退避；第 4 次失败标 failed + 告警

### F-SCHED-07 富文本

- [ ] **富文本 HTML 同样以 `multipart/alternative` 发出**
  - Phase: P6 | Ticket: P6-T05
  - 验收: 真实 Gmail 冒烟回读 Content-Type 正确

---

## 9. FAQ 隐含行为（§10）

### F-FAQ-01 月份筛选依赖 feishu_outreach_at

- [ ] **月份筛选依赖 `feishu_outreach_at`，无日期只在「全部时间」**
  - Phase: P1 | Ticket: P1-T07（见 F-BOARD-WINDOW）

### F-FAQ-02 陌生邮件不污染

- [ ] **Gmail 同步只处理飞书登记过的邮箱**
  - Phase: P3 | Ticket: P3-T07 | 后端: `isFeishuBacked` 过滤
- [ ] **陌生邮件 / 营销邮件 / 系统邮件不创建 KOL**
- [ ] **历史噪音达人需清理（迁移期）**
  - Phase: P6 | Ticket: P6-T10
  - 验收: 飞书未登记邮箱来信不入 `kols` 表；自动落「discarded_emails」审计（可选）

### F-FAQ-03 AI 失败兜底

- [ ] **AI 调用失败邮件仍入库**
  - Phase: P4 | Ticket: P4-T07
- [ ] **UI 显示「AI 分类失败，已保留邮件等待人工处理」**
  - Phase: P4 | Ticket: P4-T07
- [ ] **「重新分析」按钮触发再次 AI**
  - Phase: P4 | Ticket: P4-T09
  - 验收: 余额不足 / 401 / 超时三种场景都走 fallback；不阻塞同步

### F-FAQ-04 Gmail 重新授权

- [ ] **Refresh Token 失效时顶栏出现「重新授权 Gmail」**（详见 F-WB-SYNC-03）
- [ ] **授权完成后自动恢复同步**

---

## 验收方式

| 模块 | 验收 |
|------|------|
| 业务规则 | SQL 验证脚本（`docs/scripts/parity-*.sql`）+ Postman 集合 |
| UI 交互 | Playwright E2E（10 条核心路径，见 `e2e/parity/`） |
| 发信 | 真实 Gmail 测试账户冒烟（含 CC、富文本） |
| 同步 | 飞书测试表 + Gmail 测试邮箱双跑 diff |
| 看板 | 数字与旧系统对账（允许 ±1 容差） |
| 整体 | 本文件所有项 `[ ]` 数量 = 0 |

## Phase 6 上线准入硬条件

```bash
rg "^- \[ \]" kol-mail-desk-v2-docs/specs/05-feature-parity.md
# 期望输出：0 行；任何残留 [ ] 必须翻成 [✅] [⚠️] [🚫] 之一，[⚠️] [🚫] 需有原因注释
```

> 切线上前所有勾选必须打钩。Phase 6 验收检查清单与本文档一致。
