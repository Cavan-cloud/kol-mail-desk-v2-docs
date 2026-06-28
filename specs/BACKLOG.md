# 开发任务清单（Backlog）

> 每个 Phase 拆到 ticket 粒度。ticket ID 格式：`P{phase}-T{seq}`，全局唯一。
> 状态符号：`⬜` 未开始 / `🔄` 进行中 / `✅` 完成 / `⚠️` 完成但有缺陷 / `🚫` 决定不做（需写原因）。
> 每完成一个 ticket，必须同步更新本文件 + `STATUS.md` + `05-feature-parity.md`。

---

## 全局约定

| 字段 | 含义 |
|------|------|
| **模块** | 涉及的 Maven 模块或前端目录 |
| **依赖** | 前置 ticket（必须先完成） |
| **预估** | 人日（1d = 8h） |
| **Feature** | 关联的 `05-feature-parity.md` 章节 / 条目 |
| **DoD** | Definition of Done：必须满足的验收点 |

---

## Phase 0 — 骨架与 Harness（2～3 周）

### 概览

| Ticket | 标题 | 状态 | 预估 |
|--------|------|------|------|
| P0-T01 | 三仓库目录建立 | ✅ | 0.5d |
| P0-T02 | AGENTS.md（后端、前端） | ✅ | 0.5d |
| P0-T03 | `.cursor/rules/`（全局 + 后端 + 前端） | ✅ | 0.5d |
| P0-T04 | `harness/risk-tiers.json` | ✅ | 0.2d |
| P0-T05 | specs 中文化（00～07） | ✅ | 2d |
| P0-T06 | 决策记录 ADR-001～006 | ✅ | 1d |
| P0-T07 | 后端 `docs/standards/` 三件套 | ✅ | 1d |
| P0-T08 | 执行层文档（STATUS / BACKLOG / SETUP + 功能勾选 + mdc 协议 + phases 对账） | ✅ | 1d |
| P0-T09 | 旧仓库标记「只读参考」 | ✅ | 0.2d |
| P0-T10 | CI 模板（GitHub Actions 草案） | ✅ | 1d |
| P0-T11 | 三仓库 `git init` + 首次提交 + 远端配置 + `docker-compose.dev.yml` + `.env.example` | ✅ | 0.5d |

**Phase 0 合计：~8.4 人日 · 已完成 11 / 11** 🎉

### 详细

#### P0-T09 — 旧仓库标记「只读参考」

- **模块**: `kol-mail-desk/` 根
- **依赖**: —
- **DoD**:
  - 旧仓库根新增 `READONLY.md` 写明：参考用、禁止合入修改、仅 Phase 6 数据迁移期允许 SELECT
  - 在 `kol-mail-desk-v2-docs/README.md` "相关仓库" 中已声明（已完成）
  - 三个新仓库的 `AGENTS.md` 已有"禁止读写旧仓库"的硬规则（已完成）

#### P0-T10 — CI 模板（GitHub Actions 草案）

- **模块**: 三仓库各自 `.github/workflows/`
- **依赖**: —
- **DoD**:
  - 后端：`backend-ci.yml`（mvn verify + ArchUnit + Testcontainers + Flyway 校验）
  - 前端：`web-ci.yml`（pnpm test + pnpm build + Playwright smoke）
  - docs：`docs-ci.yml`（markdown lint + 链接检查 + OpenAPI 验证）
  - 三个 workflow 在 push / PR 时跑
  - README 中加 status badge

#### P0-T11 — 三仓库 git init + docker-compose.dev.yml

- **模块**: 仓库根
- **依赖**: P0-T01 ~ T10
- **DoD**:
  - 三仓库各自 `git init` + 首次 commit（initial commit）
  - 三仓库远端 URL 配好（GitHub Org 待定）
  - 后端仓库根 `docker-compose.dev.yml` 写好（PG 16 + Redis 7，挂卷）
  - 后端仓库根 `.env.example` 写好（按 `SETUP.md § 4.1`）
  - 前端仓库根 `.env.local.example` 写好
  - 本地 `docker compose up -d` 后能连上 PG/Redis

---

## Phase 1 — 只读核心 API + 前端壳（3～4 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P1-T01 | Maven 父 POM + 8 子模块骨架 + ArchUnit 守护 | backend | 1.5d |
| P1-T02 | Flyway 基础迁移 V1（profiles / tenants / kols / emails / ...） | infrastructure | 2d |
| P1-T03 | MyBatis-Plus 全局配置（Interceptor 链路 + MetaObjectHandler + TypeHandler） | infrastructure | 1d |
| P1-T04 | Spring Security + Google OAuth2 登录走通 | api + infrastructure | 2d |
| P1-T05 | `profiles` 落库 + 首次资料完善（display_name / role / mentor / feishu_operator_name） | application + api | 1d |
| P1-T06 | `WorkbenchController` GET（达人列表 + 详情 + 邮件） | api + application + domain | 2d |
| P1-T07 | `BoardController` GET（KPI + 漏斗 + 阶段分布 + 时间窗筛选） | api + application | 2d |
| P1-T08 | `TeamController` GET（成员列表 + 团队池查看） | api + application | 1d |
| P1-T09 | `TemplateController` GET（模板列表） | api + application | 0.5d |
| P1-T10 | `ScheduledEmailController` GET（定时邮件列表） | api + application | 0.5d |
| P1-T11 | OpenAPI 契约填充 Phase 1 全部端点（>20 个） | docs | 1d |
| P1-T12 | Next.js 项目初始化 + Tailwind / globals.css 迁入 | web | 1d |
| P1-T13 | 组件迁入（旧仓库 30 个可复用组件按白名单拷贝） | web | 2d |
| P1-T14 | `lib/api-client/` 由 OpenAPI 生成 TS 类型 + fetch 封装 | web | 1d |
| P1-T15 | 6 个页面壳接 api-client（工作台 / 看板 / 团队 / 模板 / 定时 / 登录） | web | 2.5d |
| P1-T16 | 删除旧 `lib/data` / `lib/gmail` / `lib/feishu` / `lib/supabase` / `app/api` | web | 0.5d |
| P1-T17 | E2E smoke：登录 + 进工作台 + 看板可见 | web | 1d |
| P1-T18 | dev seed 数据脚本（1 tenant + 4 user + 30 kol + 100 email + 5 template） | infrastructure | 1d |

**Phase 1 合计：~22.5 人日**

### 关键细节

#### P1-T01 — Maven 父 POM + 8 子模块骨架 + ArchUnit

- **DoD**:
  - 父 `pom.xml` 含 dependencyManagement（Spring Boot 3.3 / MyBatis-Plus 3.5.7 / Spring AI 1.0.x）
  - 8 个子模块各有 `pom.xml`，依赖方向符合 `project-structure.md`
  - `maildesk-domain/src/test/java/.../arch/ArchitectureTest.java` 守护：
    - `domain` 不依赖 `infrastructure` / `integration` / `application` / `api`
    - 业务代码禁 `import jakarta.persistence.*` / `org.hibernate.*` / `JdbcTemplate`
    - `controller` 包不依赖 `mapper`
  - `mvn -B verify` 通过（无业务代码时仅跑骨架 + ArchUnit）

#### P1-T02 — Flyway 基础迁移 V1

- **DoD**:
  - `V1__init_extensions.sql`：`CREATE EXTENSION pgcrypto`
  - `V2__init_enums.sql`：`kol_stage` / `kol_status` / `platform` / `email_direction` / `action_type`
  - `V3__init_tenants.sql`：`tenants` 表（多租户预留，dev 内置一行）
  - `V4__init_profiles.sql`：`profiles` 表
  - `V5__init_kols.sql`：`kols` 表（含 `normalized_email` generated column + `(normalized_email, feishu_operator_name)` 唯一）
  - `V6__init_emails.sql`：`emails` 表 + 索引
  - `V7__init_email_threads.sql`：邮件线程表
  - `V8__init_templates.sql`
  - `V9__init_scheduled_emails.sql`
  - `V10__init_actions.sql`：审计 log
  - 集成测试 Testcontainers 拉起 PG 16，Flyway migrate 全绿
  - 所有业务表都有 `tenant_id` / `created_at` / `updated_at` / `created_by` / `updated_by` / `deleted_at` / `version`

#### P1-T03 — MyBatis-Plus 全局配置

- **DoD**:
  - `MyBatisPlusConfig`：注册 `TenantLineInnerInterceptor` / `PaginationInnerInterceptor` / `OptimisticLockerInnerInterceptor` / `BlockAttackInnerInterceptor`
  - `AuditFieldFiller`（`MetaObjectHandler`）：自动填 `created_at` / `updated_at` / `created_by` / `updated_by`
  - `TenantLineHandler` 实现：从 `TenantContext` 取，缺失时 fallback `DEFAULT_TENANT_ID`
  - 三个 TypeHandler 在 `maildesk-common/typehandler/`：`JsonbTypeHandler` / `StringArrayTypeHandler` / `PgEnumTypeHandler<E>`
  - 集成测试覆盖：写入 KOL 时 `tenant_id` 自动注入，查询自动追加 `WHERE tenant_id = ?`

#### P1-T04 — Spring Security + Google OAuth2

- **Feature**: 登录与入职 / Google OAuth 登录
- **DoD**:
  - `application.yml` 配 `spring.security.oauth2.client.registration.google`
  - scope 含 `email profile https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send`
  - 同意页明确告知 Gmail 权限（前端登录页文案 + Google 控制台 OAuth 同意屏配置）
  - Refresh token 加密入 `integration_credentials`（AES-256，主密钥来自 `TOKEN_ENCRYPTION_KEY`）
  - 登录成功后写 HttpOnly cookie（`SESSION`），有效期 7 天，sliding 续期
  - 单元 + 集成测试（mock OAuth Authorization Server）

---

## Phase 2 — 飞书同步（2～3 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P2-T01 | `FeishuClient`（拉 Sheet / Bitable） | integration/feishu | 1.5d |
| P2-T02 | 飞书字段映射 + 阶段映射（10 阶段 v3.3 §6） | application + common | 1d |
| P2-T03 | `FeishuSyncService` upsert KOL（`(normalized_email, feishu_operator_name)` 复合唯一） | application | 1.5d |
| P2-T04 | `feishu_operator_name` 保存后自动归属（无主才认领） | application | 1d |
| P2-T05 | `POST /api/v1/sync/feishu` + 进度查询 + 前端按钮接入 | api + web | 1d |
| P2-T06 | Worker `FeishuDeltaSyncJob` 每 30 分钟 + Redis 分布式锁 | worker | 1d |
| P2-T07 | 飞书严格只读 ArchUnit 守护（禁止飞书写 API） | domain test | 0.5d |
| P2-T08 | 飞书全量回填 CLI：`mvn -pl maildesk-worker spring-boot:run -Dspring.profiles.active=backfill` | worker | 1d |
| P2-T09 | 阶段映射 SQL 验收脚本（生成 diff 报表） | docs/scripts | 0.5d |

**Phase 2 合计：~9 人日**

---

## Phase 3 — Gmail 同步（3～4 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P3-T01 | `GmailClient` 封装（messages.list / history.list / get full） | integration/gmail | 1.5d |
| P3-T02 | `integration_credentials` 表 + AES-256 加密存取 | infrastructure | 1d |
| P3-T03 | OAuth token 刷新 + 失效检测 | infrastructure | 1d |
| P3-T04 | 「重新授权 Gmail」流程（前端 + 后端 redirect） | api + web | 1d |
| P3-T05 | `GmailSyncService.incremental`（history.list + 2 天 safety net） | application | 2d |
| P3-T06 | `GmailSyncService.history`（messages.list + pageToken 续传，并发 4） | application | 2d |
| P3-T07 | `persistGmailSync`：飞书达人过滤 + 已读规则 + reply_resolved 清理 | application | 2d |
| P3-T08 | `POST /api/v1/sync/gmail`（mode、pageToken）+ 前端 button | api + web | 1d |
| P3-T09 | Worker `GmailIncrementalSyncJob` 每 2~5 分钟 | worker | 1d |
| P3-T10 | Gmail 同步集成测试（录制 fixture，无需真实账号） | application test | 1.5d |

**Phase 3 合计：~14 人日**

---

## Phase 4 — Spring AI（2 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P4-T01 | Spring AI starter + Kimi OpenAI 兼容 base-url 配置 | ai | 0.5d |
| P4-T02 | Prompt 模板从旧 `lib/ai/prompts.ts` 迁到 `resources/prompts/*.st` | ai | 1d |
| P4-T03 | `AiService.classifyEmail`（8k 模型 + JSON schema 严格输出） | ai | 1.5d |
| P4-T04 | `AiService.generateReplyDraft`（128k） | ai | 1d |
| P4-T05 | `AiService.checkDraft`（8k） | ai | 1d |
| P4-T06 | `AiService.translateText`（128k） | ai | 1d |
| P4-T07 | 降级 fallback（无 Key / 401 / 余额不足 → 邮件仍入库，UI 显示「AI 失败」） | ai | 1d |
| P4-T08 | Gmail 同步链路接 AI（新邮件触发分类，已存在邮件跳过） | application | 1d |
| P4-T09 | 「重新分析」按钮 API（手动触发对单封邮件再次 AI） | api + web | 0.5d |
| P4-T10 | `ai_usage_log` 表 + 记录 token / 耗时 / 成本估算 | infrastructure | 1d |

**Phase 4 合计：~9.5 人日**

---

## Phase 5 — 写操作与发信（3 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P5-T01 | KOL 改名（仅工作台显示名） | api + application | 0.5d |
| P5-T02 | KOL 阶段人工校准 | api + application | 0.5d |
| P5-T03 | 标记/取消「无需回复」 | api + application | 0.5d |
| P5-T04 | 邮件标记已读 / 未读 | api + application | 0.5d |
| P5-T05 | 邮件删除（软删） | api + application | 0.5d |
| P5-T06 | Gmail 发信单发（multipart/alternative + CC + 富文本 HTML） | integration/gmail + application | 2d |
| P5-T07 | 批量跟进 `POST /api/v1/gmail/batch-send`（串行限流，每封独立记录） | application | 1.5d |
| P5-T08 | 发信成功后写 outbound `emails` + 更新 `kol.last_outbound_at` + 模板 used_count++ | application | 1d |
| P5-T09 | 模板 CRUD + 变量替换 | api + application | 1.5d |
| P5-T10 | Team 编辑资料（角色 / mentor / 飞书运营名） | api + application | 0.5d |
| P5-T11 | Team 标记离职（Leader 权限）→ 名下 KOL 进入团队池 | api + application | 1d |
| P5-T12 | Team 池分配 KOL（Leader 权限） | api + application | 1d |
| P5-T13 | 审计 `@AuditAction` + AOP 切面（所有写操作织入 `actions` 表） | application | 1.5d |
| P5-T14 | 前端 `DraftSendPanel` 全功能（富文本 + CC + 模板插入 + 定时） | web | 2.5d |
| P5-T15 | 前端 `KolNameEditor` / `KolStageEditor` / `ReplyResolvedButton` 接 API | web | 1d |
| P5-T16 | 前端 `MarkEmailReadButton` / `AutoMarkRead` / `DeleteEmailButton` 接 API | web | 1d |
| P5-T17 | 前端 `TemplateLibrary` CRUD | web | 1d |
| P5-T18 | 前端 `BatchFollowupButton` 接 API（含进度反馈） | web | 1d |
| P5-T19 | 前端 Team 页面 + `AssignPanel` 接 API | web | 1d |
| P5-T20 | 真实 Gmail 冒烟（自发自收 + CC + 富文本回读） | qa | 0.5d |

**Phase 5 合计：~20 人日**

---

## Phase 6 — 定时邮件 + 生产化（2 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P6-T01 | `scheduled_emails` 状态机（scheduled / processing / sent / failed / cancelled） | domain | 0.5d |
| P6-T02 | 定时邮件 CRUD + 发送前取消 | api + application | 1d |
| P6-T03 | Worker `ScheduledEmailDispatchJob` 每分钟原子认领（`UPDATE ... RETURNING`） | worker | 1.5d |
| P6-T04 | 失败重试 ≤3 次，指数退避；超过停止 + UI 显示 failed | worker | 1d |
| P6-T05 | 富文本 `english_body_html` 字段保留 + 发送 | application + integration/gmail | 0.5d |
| P6-T06 | Docker 镜像（API + Worker 各一）+ multi-stage Dockerfile | ops | 1d |
| P6-T07 | K8s manifests / Helm chart | ops | 2d |
| P6-T08 | OpenTelemetry + Prometheus + Grafana dashboard（同步耗时 / AI 失败率 / Worker lag） | ops | 2d |
| P6-T09 | 监控告警规则（Gmail 同步失败 > 阈值 / AI 失败率 > 10% / Worker lag > 5min） | ops | 1d |
| P6-T10 | 数据迁移脚本（旧 Supabase → 新 PG），含 diff 校验 | ops/scripts | 3d |
| P6-T11 | 双跑 + 切流方案演练（dry-run） | ops | 1d |
| P6-T12 | 回滚预案 + Runbook | ops | 0.5d |
| P6-T13 | 生产环境密钥进 Secrets Manager（不写 yml） | ops | 0.5d |

**Phase 6 合计：~15.5 人日**

---

## Phase 7 — SaaS 增强（可选，4～6 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P7-T01 | Gmail Push（Pub/Sub）+ Webhook 近实时同步 | integration/gmail + worker | 3d |
| P7-T02 | Gmail Watch 续订 Job（每天） | worker | 1d |
| P7-T03 | 全链路 `tenant_id` 验证 + RLS 启用 | infrastructure | 2d |
| P7-T04 | 平台管理后台（租户管理 / 配额 / 用量报表） | api + web | 5d |
| P7-T05 | 租户 onboarding 流程（邀请 → 创建租户 → 初始化 owner） | application + web | 3d |
| P7-T06 | OpenSearch 集成 + 全文搜索（达人 / 邮件 / AI 摘要） | infrastructure + api | 4d |
| P7-T07 | SSO（SAML / OIDC） | api | 4d |
| P7-T08 | Stripe 计费（可选） | api + web | 5d |

**Phase 7 合计：~27 人日（可选范围）**

---

## ticket 状态汇总

> 自动统计脚本（Phase 6 末期补）会扫描本文件，输出"未开始 / 进行中 / 完成"数字到 STATUS.md。

当前手工统计（D0）：

| Phase | 总数 | ✅ | 🔄 | ⬜ | 完成率 |
|-------|------|----|----|----|--------|
| P0 | 11 | 11 | 0 | 0 | 100% |
| P1 | 18 | 0 | 0 | 18 | 0% |
| P2 | 9 | 0 | 0 | 9 | 0% |
| P3 | 10 | 0 | 0 | 10 | 0% |
| P4 | 10 | 0 | 0 | 10 | 0% |
| P5 | 20 | 0 | 0 | 20 | 0% |
| P6 | 13 | 0 | 0 | 13 | 0% |
| P7 | 8 | 0 | 0 | 8 | 0% |
| **总计** | **99** | **11** | **0** | **88** | **11%** |

---

## 协作约定

1. **挑选 ticket**：从 STATUS.md 的"当前活跃 ticket"接续；若该 ticket 已完成，从同 Phase 中"⬜ 未开始且依赖已满足"中选下一个
2. **ticket 进入 🔄**：在本文件标记 🔄 + 更新 STATUS.md "当前活跃 ticket"
3. **ticket 完成 ✅**：本文件 + STATUS.md + 05-feature-parity.md 三处同步更新，commit 时一并纳入
4. **拆 ticket**：单 ticket 超过 2 人日的，先拆为子 ticket（P{n}-T{n}.{sub}）再做
5. **跨 Phase 影响**：若某 ticket 暴露出会影响后续 Phase 的设计问题，先停下开 ADR 评审，不要硬塞
6. **🚫 决定不做**：必须在 ticket 项注明原因，并在 `07-risks.md` 评估遗留风险
