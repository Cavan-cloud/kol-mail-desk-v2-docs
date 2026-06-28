# 分阶段开发计划

## 总览

| Phase | 主题 | 周期 | 状态 |
|-------|------|------|------|
| 0 | 骨架 + Harness | 2～3 周 | **进行中** |
| 1 | 只读核心 API + 前端壳 | 3～4 周 | 待开始 |
| 2 | 飞书同步 | 2～3 周 | 待开始 |
| 3 | Gmail 同步 | 3～4 周 | 待开始 |
| 4 | Spring AI | 2 周 | 待开始 |
| 5 | 写操作与发信 | 3 周 | 待开始 |
| 6 | 定时邮件 + 生产化 | 2 周 | 待开始 |
| 7（可选） | SaaS 增强 | 4～6 周 | 未来 |

**总工期：约 17～22 周（4～5.5 个月）达到 v3.3 功能对齐。**

每个 Phase 的具体 ticket 拆分见 `BACKLOG.md` 对应章节；当前进度见 `STATUS.md`。

---

## 全局准入 / 收尾协议

### 进入下一 Phase 的硬条件

1. 当前 Phase 在 `BACKLOG.md` 的所有 ticket 状态必须是 `✅` 或 `🚫`（带书面原因）
2. 当前 Phase 涉及的 `05-feature-parity.md` 条目必须翻成 `[✅]` 或 `[⚠️]` 或 `[🚫]`（不能残留 `[ ]`）
3. `mvn -B verify`（后端）+ `pnpm build`（前端）全绿
4. 该 Phase 新增/修改的 API 已写入 `api-contract-v1.yaml`
5. 该 Phase 关键决策已落 ADR
6. `STATUS.md` 已更新到下一 Phase

### 收尾对账脚本

```bash
# 1. 当前 Phase 是否有未关闭 ticket
rg "^\| P{N}-T\d+ .*⬜" kol-mail-desk-v2-docs/specs/BACKLOG.md
# 期望：0 行

# 2. 当前 Phase 关联 feature 是否全部 [✅]
rg "^- \[ \]" kol-mail-desk-v2-docs/specs/05-feature-parity.md | rg "Phase: P{N}"
# 期望：0 行
```

每个 Phase 在「验收」章节末尾都会指明本 Phase 关联的 feature-parity 范围。

---

## Phase 0 — 骨架与 Harness

**目标：** 给后续 Phase 提供清晰的「轨道」。

### 交付物

- [x] 三个独立仓库目录建立
  - `/Users/chenkaifeng/code/kol-mail-desk-v2-docs`
  - `/Users/chenkaifeng/code/kol-mail-desk-v2-backend`
  - `/Users/chenkaifeng/code/kol-mail-desk-v2-web`
- [x] AGENTS.md（后端、前端）
- [x] `.cursor/rules/`（00-global、backend-java、frontend-next）
- [x] `harness/risk-tiers.json`
- [x] specs 中文化（00～07）
- [x] 决策记录 ADR-001～005
- [ ] 旧仓库标记「只读参考」
- [ ] CI 模板（GitHub Actions 草案）

### 验收

- 三个 repo 各自 `git init`，README 可读
- Cursor 加载 `.cursor/rules` 不报错
- 任意 Agent 任务可以读到 `specs/00-refactor-plan.md`

### 关联 BACKLOG ticket

`P0-T01 ~ P0-T11`（详见 `BACKLOG.md § Phase 0`）

### 关联 feature-parity

无（基础设施 Phase，不涉及具体 v3.3 功能）

---

## Phase 1 — 只读核心 API + 前端壳

**目标：** 后端能返回工作台 / 看板 / 团队等只读数据；前端能渲染所有页面壳。

### 后端交付物

- [ ] Maven 多模块工程初始化（8 个 module）
- [ ] PostgreSQL 16 + Flyway，从旧 migration 转为 V1～V10
- [ ] Spring Security + OAuth2 最小实现（Google 登录可走通）
- [ ] `WorkbenchController`、`BoardController`、`TeamController`、`TemplateController`、`ScheduledEmailController`（仅 GET）
- [ ] `api-contract-v1.yaml` 填充 Phase 1 端点
- [ ] 单元测试：JUnit 5 + Testcontainers（PG + Redis）

### 前端交付物

- [ ] Next.js 15 项目初始化
- [ ] 从旧仓库迁入：
  - `components/`（30 个）
  - `lib/domain.ts`、`lib/workbench.ts`、`lib/team.ts`
  - Tailwind / PostCSS 配置、`app/globals.css`
- [ ] 新建 `lib/api-client/`，对接 OpenAPI 类型
- [ ] 6 个 SSR 页面接 api-client：
  - `app/page.tsx`（工作台）
  - `app/board/page.tsx`
  - `app/team/page.tsx`
  - `app/templates/page.tsx`
  - `app/scheduled/page.tsx`
  - `app/login/page.tsx`
- [ ] 删除 `lib/data/`、`lib/gmail/`、`lib/feishu/`、`lib/supabase/`、`app/api/`

### 验收

- 登录后能进工作台（数据可空）
- 看板、团队、模板、定时页面全部可访问
- 前端无 Supabase / Gmail / 飞书直连
- `mvn verify` + `npm run build` 均通过

### 关联 BACKLOG ticket

`P1-T01 ~ P1-T18`（详见 `BACKLOG.md § Phase 1`）

### 关联 feature-parity（涉及部分）

- F-AUTH-01 ~ F-AUTH-04（登录与首次资料）
- F-WB-NAV-01、F-WB-SIDE-01~04（侧栏统计 GET）
- F-WB-SEARCH-01（搜索基础）
- F-WB-LIST-01 ~ F-WB-LIST-02（达人列表 GET）
- F-WB-DETAIL-01（详情字段展示）
- F-WB-EMAIL-01 ~ F-WB-EMAIL-03（邮件渲染基础）
- F-BOARD-KPI / F-BOARD-WINDOW / F-BOARD-PIPELINE / F-BOARD-RATIO（看板 GET）
- F-TEAM-LIST（成员列表 GET）
- F-TPL-01（模板列表 GET）
- F-SCHED-02（定时邮件列表 GET）

---

## Phase 2 — 飞书同步

**目标：** 飞书表里 1000+ 达人能同步进新库。

### 交付物

- [ ] `FeishuIntegrationClient`（移植旧 `lib/feishu/sync-kols.ts`）
- [ ] 字段映射、阶段映射表（v3.3 §6 完整对照）
- [ ] `(normalized_email, feishu_operator_name)` 唯一键 upsert
- [ ] 保存 `feishu_operator_name` 后批量归属
- [ ] `POST /api/v1/sync/feishu` 手动触发 + 进度查询
- [ ] CLI 工具：`mvn -pl maildesk-worker spring-boot:run -Dspring.profiles.active=backfill`（全量回填）
- [ ] 前端 `FeishuSyncButton` 接新 API

### 验收

- 测试环境飞书数据全量同步成功（≥1000 条）
- 阶段映射结果与 v3.3 §6 一致（写 SQL 验收脚本）
- 同步只读，飞书侧无任何写入痕迹
- `source=manual` 字段不被覆盖

### 关联 BACKLOG ticket

`P2-T01 ~ P2-T09`

### 关联 feature-parity

- F-AUTH-05（飞书运营名归属）
- F-WB-LIST-03（10 阶段映射）
- F-STAGE-01 ~ F-STAGE-04（阶段映射 + 飞书只读）

---

## Phase 3 — Gmail 同步

**目标：** 每个成员能拉取自己 Gmail，与飞书达人聚合。

### 交付物

- [ ] Spring Security OAuth2 客户端配置（Google + Gmail scope）
- [ ] `integration_credentials` 表（AES-256 加密 Token）
- [ ] `GmailSyncService` 移植：
  - 增量（`history.list` + 2 天 safety net）
  - 历史（`messages.list` + pageToken 续传）
  - 并发 4，`format=full`
- [ ] `persistGmailSync` 移植：
  - 飞书达人过滤（`isFeishuBacked`）
  - 已读规则（INSERT 时从 `UNREAD` 写入；UPDATE 不覆盖）
  - 新 inbound 清 `reply_resolved`
- [ ] Worker `GmailIncrementalSyncJob`（每 2～5 分钟）
- [ ] `POST /api/v1/sync/gmail`（mode、pageToken）
- [ ] 前端 `GmailSyncButton` 接新 API（保留客户端循环）

### 验收

- 同步邮件入库，AI 字段为 fallback（Phase 4 才接 AI）
- 陌生人邮件不创建 KOL
- 历史同步分页正确续传
- 手动「重新授权 Gmail」流程可用

### 关联 BACKLOG ticket

`P3-T01 ~ P3-T10`

### 关联 feature-parity

- F-AUTH-06（首次登录历史同步引导）
- F-WB-SYNC-01（同步 Gmail 按钮）
- F-WB-SYNC-03（重新授权 Gmail）
- F-WB-SYNC-04（同步非阻塞）
- F-WB-STATE-04（新 inbound 清 reply_resolved）
- F-FAQ-02（陌生邮件不污染）
- F-FAQ-04（Refresh Token 失效流程）

---

## Phase 4 — Spring AI

**目标：** AI 分类、翻译、草稿、自检 4 个能力可用。

### 交付物

- [ ] `spring-ai-openai-spring-boot-starter`，`base-url = https://api.moonshot.cn/v1`
- [ ] Prompt 从旧 `lib/ai/prompts.ts` 移到 `resources/prompts/*.st`
- [ ] `AiService`：
  - `classifyEmail`（8k 模型 + JSON schema）
  - `generateReplyDraft`（128k）
  - `checkDraft`（8k）
  - `translateText`（128k）
- [ ] 降级 fallback（无 Key 或 API 失败）
- [ ] 同步链路接 AI（已存在邮件跳过）
- [ ] 重新分类按钮 API
- [ ] `ai_usage_log` 记录 token 与耗时

### 验收

- v3.3 §10：AI 失败邮件仍入库，显示「AI 分类失败」
- 草稿中英双版同时返回
- 8k / 128k 模型按场景分流（成本控制）
- AI 调用 P95 < 8s

### 关联 BACKLOG ticket

`P4-T01 ~ P4-T10`

### 关联 feature-parity

- F-STAGE-02（AI 不决定阶段）
- F-WB-LIST-02（AI 摘要列）
- F-FAQ-03（AI 失败兜底）

---

## Phase 5 — 写操作与发信

**目标：** 所有用户写操作上线，工作台真正可用。

### 后端交付物

- [ ] KOL：改名、阶段校准、标记/取消无需回复
- [ ] Email：标记已读 / 未读、删除
- [ ] Send：单发、批量、CC、HTML（multipart/alternative）
- [ ] Template：CRUD、变量替换、`used_count++`
- [ ] Team：编辑资料、离职（Leader）、分配（Leader）
- [ ] Audit：所有写操作写 `actions` 表

### 前端交付物

- [ ] `DraftSendPanel` 全功能
- [ ] `BatchFollowupButton` 接 `/api/v1/gmail/batch-send`
- [ ] `KolNameEditor` / `KolStageEditor` / `ReplyResolvedButton`
- [ ] `MarkEmailReadButton` / `AutoMarkRead` / `DeleteEmailButton`
- [ ] `TemplateLibrary` CRUD
- [ ] Team 页面 + `AssignPanel`

### 验收

- 真实 Gmail 测试账户冒烟：发信、CC、HTML 渲染正确
- 批量跟进串行限流、每封单独记录
- 离职后 KOL 进入团队池，Leader 能分配
- 模板使用次数自动 +1

### 关联 BACKLOG ticket

`P5-T01 ~ P5-T20`

### 关联 feature-parity

- F-WB-SYNC-02（批量跟进）
- F-WB-DETAIL-02 ~ F-WB-DETAIL-03（改名 / 阶段校准）
- F-WB-STATE-01 ~ F-WB-STATE-03（无需回复 / 已读未读）
- F-WRITE-01 ~ F-WRITE-10（撰写回复全套）
- F-TEAM-OP（团队成员操作全套）
- F-TPL-02 ~ F-TPL-06（模板 CRUD + 变量 + 使用计数）
- 所有写操作的审计 log（贯穿）

---

## Phase 6 — 定时邮件 + 生产化

**目标：** 定时邮件端到端；生产环境上线。

### 后端交付物

- [ ] `scheduled_emails` 状态机
- [ ] Worker `ScheduledEmailDispatchJob`（每分钟、原子认领、≤3 次重试）
- [ ] 富文本（保留 `english_body_html`）支持
- [ ] CRON_SECRET 替换为 Worker 内部调度（不对外）

### 运维交付物

- [ ] Docker 镜像（API、Worker 各一）
- [ ] K8s manifests / Helm chart
- [ ] OpenTelemetry + Prometheus + Grafana dashboard
- [ ] 数据迁移脚本（旧 Supabase → 新 PG）
  - 双跑期：旧系统继续运行，新系统并行
  - 切流：DNS / Vercel 切到新前端
  - 回滚预案：保留旧系统至少 2 周
- [ ] 监控告警（Gmail 同步失败、AI 失败率、Worker lag）

### 验收

- scheduled → sent 端到端通过（含富文本）
- 同一定时邮件多 Worker 不会重复发送
- 失败 3 次后停止重试，UI 显示状态
- 数据迁移后行数、聚合数字与旧系统一致（diff 报表）

### 关联 BACKLOG ticket

`P6-T01 ~ P6-T13`

### 关联 feature-parity

- F-SCHED-01 ~ F-SCHED-07（定时邮件全套）

### **Phase 6 = v3.3 上线准入**

完成 Phase 6 = v3.3 功能对齐 + 可上线。**必须满足**：

```bash
rg "^- \[ \]" kol-mail-desk-v2-docs/specs/05-feature-parity.md
# 期望输出：0 行；任何残留 [ ] 必须翻成 [✅] [⚠️] [🚫] 之一
```

未达成 → 不允许切流。

---

## Phase 7（可选）— SaaS 增强

**目标：** 平台化扩展。

### 交付物

- [ ] Gmail Push（Pub/Sub）+ Webhook 近实时同步
- [ ] `tenant_id` 全链路 + RLS 启用
- [ ] 租户 onboarding 流程 + Stripe 计费（可选）
- [ ] OpenSearch 全文搜索（达人 / 邮件 / AI 摘要）
- [ ] 平台管理后台（租户管理、配额、用量报表）
- [ ] SSO（SAML / OIDC）

---

## 跨 Phase 的工程实践

### 提交规范

- 分支：`feature/{phase}-{slug}`、`fix/{slug}`
- Commit：Conventional Commits（`feat:`、`fix:`、`refactor:`、`docs:`）
- 每个 PR 必须更新对应 spec / OpenAPI

### Code Review

- 后端：2 人 review，集成层（gmail/feishu/security）需要 TL review
- 前端：1 人 review，可复用组件改动需要 TL review

### 测试门槛

- Phase 1+：后端单元测试覆盖率 >= 60%
- Phase 3+：Gmail/飞书集成测试用录制 fixture
- Phase 5+：E2E 覆盖 v3.3 §3、§4、§5、§7、§8、§9 主流程

### 文档同步

- API 变更 → 改 `api-contract-v1.yaml`
- 业务规则变更 → 改对应 spec
- 风险新增 → 改 `07-risks.md`
- 关键决策 → 新增 ADR
