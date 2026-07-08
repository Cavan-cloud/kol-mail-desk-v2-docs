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
| P1-T01 | Maven 父 POM + 8 子模块骨架 + ArchUnit 守护 | backend | 1.5d | ✅ |
| P1-T02 | Flyway 基础迁移 V1（profiles / tenants / kols / emails / ...） | infrastructure | 2d | ✅ ⚠️ |
| P1-T03 | MyBatis-Plus 全局配置（Interceptor 链路 + MetaObjectHandler + TypeHandler） | infrastructure | 1d | ✅ ⚠️ |
| P1-T04 | Spring Security + Google OAuth2 登录走通 | api + infrastructure | 2d | ✅ ⚠️ |
| P1-T05 | `profiles` 落库 + 首次资料完善（display_name / role / mentor / feishu_operator_name） | application + api | 1d | ✅ |
| P1-T06 | `WorkbenchController` GET（达人列表 + 详情 + 邮件） | api + application + domain | 2d | ✅ |
| P1-T07 | `BoardController` GET（KPI + 漏斗 + 阶段分布 + 时间窗筛选） | api + application | 2d | ✅ |
| P1-T08 | `TeamController` GET（成员列表 + 团队池查看） | api + application | 1d | ✅ |
| P1-T09 | `TemplateController` GET（模板列表） | api + application | 0.5d | ✅ |
| P1-T10 | `ScheduledEmailController` GET（定时邮件列表） | api + application | 0.5d | ✅ |
| P1-T11 | OpenAPI 契约填充 Phase 1 全部端点（>20 个） | docs | 1d | ✅ |
| P1-T12 | Next.js 项目初始化 + Tailwind / globals.css 迁入 | web | 1d | ✅ |
| P1-T13 | 组件迁入（旧仓库 30 个可复用组件按白名单拷贝） | web | 2d | ✅ |
| P1-T14 | `lib/api-client/` 由 OpenAPI 生成 TS 类型 + fetch 封装 | web | 1d | ✅ |
| P1-T15 | 6 个页面壳接 api-client（工作台 / 看板 / 团队 / 模板 / 定时 / 登录） | web | 2.5d | ✅ |
| P1-T16 | 删除旧 `lib/data` / `lib/gmail` / `lib/feishu` / `lib/supabase` / `app/api` | web | 0.5d | ✅ |
| P1-T17 | E2E smoke：登录 + 进工作台 + 看板可见 | web | 1d | ✅ |
| P1-T18 | dev seed 数据脚本（1 tenant + 4 user + 30 kol + 100 email + 5 template） | infrastructure | 1d | ✅ ⚠️ |

**Phase 1 合计：~22.5 人日**

#### P1-T06 ~ P1-T10 — 只读核心 API ✅

> **完成（2026-06-30）**：`maildesk-application` 新增 5 个 ApplicationService（`Workbench` / `Board` / `Team` / `Template` / `ScheduledEmail`）+ 支撑类 `StageCatalog` / `BoardWindow` / `WorkbenchRules` / `EntityMappers`；`maildesk-api` 新增 `WorkbenchController`、`KolController`、`BoardController`、`TemplateController`、`ScheduledEmailController`，扩展 `TeamController` `GET /members`（T05 已有 `PATCH /profile`）。`mvn -pl maildesk-api -am verify` BUILD SUCCESS。
>
> **端点**：`GET /api/v1/workbench` · `GET /api/v1/kols/{kolId}` · `GET /api/v1/board` · `GET /api/v1/team/members` · `GET /api/v1/templates` · `GET /api/v1/scheduled-emails`
>
> **📌 已知差异（待 T15 联调）**：Board `publishedKols` 用阶段累计启发式；Pool 视图未实现 legacy compose 第三条「他人 stalled」规则；无 MockMvc 集成测试。

#### P1-T15 — 6 页面壳接 api-client ✅

> **完成（2026-06-30）**：`app/{page,board,team,templates,scheduled,login,onboarding}` + `components/pages/*`；`RequireAuth` + TanStack Query hooks；`lib/api-mapper.ts` / `lib/workbench-nav.ts` / `lib/auth-url.ts`；`types.gen.ts` 重生成（含 `TeamProfileUpdateRequest.displayName`）；`tsc --noEmit` 通过。
>
> **路由**：`/` 工作台 · `/board` · `/team` · `/templates` · `/scheduled` · `/login` · `/onboarding`（pending_approval 引导）
>
> **📌 遗留**：写操作按钮（发信/同步/编辑成员）仍调后端 Phase 5+ 端点，Phase 1 只读壳可展示但可能 501；E2E 待 T17。

#### P1-T16 — legacy 清理与 import 守护 ✅

> **完成（2026-06-30）**：v2-web 从未引入 `lib/data|gmail|feishu|supabase|app/api`；新增 ESLint `no-restricted-imports` + `lib/__tests__/forbidden-legacy.test.ts`（6 项）；清理 `domain.ts` / `ReplyResolvedButton` 中 legacy 注释引用。

#### P1-T17 — Playwright @smoke E2E ✅

> **完成（2026-06-30）**：`playwright.config.ts` + `e2e/smoke/routes.spec.ts`（4 条 @smoke，mock `**/api/v1/**` 无需 OAuth）；`vitest.config.ts` 排除 e2e；CI 启用 Playwright chromium + smoke grep。
>
> **📌 待办**：本机 `pnpm install` 更新 lockfile 后 CI 可恢复 `--frozen-lockfile`。

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

#### P1-T02 — Flyway 基础迁移 V1 ✅⚠️

> **完成（2026-06-29）**：写了 V1~V13 共 13 个迁移（pgcrypto / 5 枚举 / tenants+dev 租户 / profiles / kols / emails / email_threads / templates / scheduled_emails / actions + v2 新增 integration_credentials / sync_jobs / ai_usage_log）；所有业务表统一 `tenant_id`+审计/软删/乐观锁列；去掉 Supabase auth.users 外键与 RLS（隔离改由 MyBatis TenantLineInnerInterceptor）；profiles 明文 token 列移除（改 AES 加密存 integration_credentials）。infrastructure pom 增 Flyway/PG/Testcontainers/starter-test 并启用 failsafe，新增 `FlywayMigrationIT`。`mvn -pl maildesk-infrastructure -am verify` BUILD SUCCESS、ArchUnit 4/4 绿。
> **⚠️ 遗留**：本机无 Docker，`FlywayMigrationIT` 经 `assumeTrue` 优雅跳过、未实跑真实迁移 → 需带 Docker 的 CI 跑通后实锤。

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

#### P1-T03 — MyBatis-Plus 全局配置 ✅⚠️

> **完成（2026-06-29）**：`MyBatisPlusConfig` 注册 4 拦截器（TenantLine → Pagination(PG) → OptimisticLocker → BlockAttack）；`AuditFieldFiller`（MetaObjectHandler）自动填充 createdAt/updatedAt/createdBy/updatedBy；`MaildeskTenantLineHandler` 从 `TenantContext`(ThreadLocal) 取，缺失 fallback `DEFAULT_TENANT_ID`，并 `ignoreTables` 跳过 `tenants` 等元数据表；3 个 PG TypeHandler（`JsonbTypeHandler` / `StringArrayTypeHandler` / `PgEnumTypeHandler` + 2 具体 enum 子类）走 `ConfigurationCustomizer` 注册（`StringArrayTypeHandler` 因泛型擦除问题改为 `@TableField` 字段级注解）；新建 `TenantContext` / `UserContext`、`KolStage` / `EmailDirection` 枚举、`TenantDO` / `KolDO` / `EmailDO` + Mapper、api 与 worker `application.yml` 接好 datasource / flyway / mybatis-plus。`mvn -pl maildesk-infrastructure -am verify` BUILD SUCCESS（4s），ArchUnit 4/4 绿。
> **⚠️ 遗留**：`MyBatisPlusConfigIT` 写了 10 项断言（默认 tenant 注入 / TenantContext 切换 / 分页 / 乐观锁 / JSONB·TEXT[]·PG enum round-trip / 软删 / tenants 表免注入 / KolStage 全集对照），本机无 Docker 经 `assumeTrue` 跳过，待 CI 实锤。
> **📌 接入提醒**：api / worker 启动类仍 `exclude=DataSourceAutoConfiguration.class` 且未把 infrastructure 加入运行时依赖，P1-T04 须一并解除。

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

> **🐛 真实浏览器联调发现并修复（2026-07-04）**：本地首次用真实 Google 账号端到端登录时复现"登录成功后又跳回登录页，重试多次都进不去"。
> 根因：Spring Security 默认把 `oauth2Login` 成功后的 `OAuth2AuthenticationToken` 持久化进 `JSESSIONID` 对应的 HttpSession；此后每个请求 `SecurityContextHolderFilter` 会先从该 HttpSession 恢复这个"陈旧" Google 身份，抢在 `SessionCookieAuthenticationFilter`（只在 `getAuthentication() == null` 时才生效）之前占位，导致基于 Redis 的 `MAILDESK_SESSION` 会话被跳过 → 请求判定未登录 → 401 → 前端弹回 `/login`；且每次重新登录都会往同一个 JSESSIONID 会话里再种一次，永久死循环。
> 修复：`SecurityConfig` 增加 `.securityContext(ctx -> ctx.securityContextRepository(new NullSecurityContextRepository()))`，禁止 Spring Security 读写 HttpSession 里的认证上下文（OAuth2 授权过程中的临时 state 走独立的 `AuthorizationRequestRepository`，不受影响）。修复后用真实浏览器 cookie 重放请求验证通过。
> 遗留：`P1-T04` 之前标注的"OAuth 端到端集成测试待 Gmail 同步 ticket 联调"至此已用真实账号验证通过；建议后续补一个针对"JSESSIONID + MAILDESK_SESSION 共存"场景的回归测试，防止此问题复现。

---

## Phase 2 — 飞书同步（2～3 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P2-T01 | `FeishuClient`（拉 Sheet / Bitable） | integration/feishu | 1.5d | ✅ |
| P2-T02 | 飞书字段映射 + 阶段映射（10 阶段 v3.3 §6） | application + common | 1d | ✅ |
| P2-T03 | `FeishuSyncService` upsert KOL（`(normalized_email, feishu_operator_name)` 复合唯一） | application | 1.5d | ✅ |
| P2-T04 | `feishu_operator_name` 保存后自动归属（无主才认领） | application | 1d | ✅ |
| P2-T05 | `POST /api/v1/sync/feishu` + 进度查询 + 前端按钮接入 | api + web | 1d | ✅ |
| P2-T06 | Worker `FeishuDeltaSyncJob` 每 30 分钟 + Redis 分布式锁 | worker | 1d | ✅ |
| P2-T07 | 飞书严格只读 ArchUnit 守护（禁止飞书写 API） | domain test | 0.5d | ✅ |
| P2-T08 | 飞书全量回填 CLI：`mvn -pl maildesk-worker spring-boot:run -Dspring.profiles.active=backfill` | worker | 1d | ✅ |
| P2-T09 | 阶段映射 SQL 验收脚本（生成 diff 报表） | docs/scripts | 0.5d | ✅ |

**Phase 2 合计：~9 人日**

#### P2-T01 — `FeishuClient`（拉 Sheet / Bitable）✅

> **完成（2026-06-30）**：`maildesk-domain` 新增 `FeishuClient` 端口 + `FeishuSheetMeta` / `FeishuBitableRecord` / `FeishuConfigCheckResult`；`maildesk-integration` 实现 `FeishuClientImpl`（RestTemplate + tenant token 内存缓存 + Sheet 400 行分批读取 + Bitable 100 条分页 + 3 次指数退避重试）；`FeishuProperties` + `FeishuAutoConfiguration`；`application.yml` / worker yml 增加 `maildesk.feishu.*`；7 项 `FeishuClientImplTest`（MockRestServiceServer）。HTTP 行为移植自 legacy `lib/feishu/sync-kols.ts`；字段/阶段映射留给 P2-T02。
>
> **端点（只读）**：`auth/v3/tenant_access_token/internal` · `sheets/v3/.../sheets/query` · `sheets/v2/.../values/{range}` · `bitable/v1/.../records`

#### P2-T02 — 飞书字段映射 + 阶段映射 ✅

> **完成（2026-07-01）**：`maildesk-common` 新增 `FeishuStageMapper`（v3.3 §6 完整对照，行政标记返回 null 保留现有阶段）+ `FeishuCellExtractor`（单元格文本/邮箱/URL/运营名/mergeKey）；`maildesk-application/sync/feishu` 新增 `FeishuFieldHeaders`（默认表头候选）· `FeishuColumnResolver` · `FeishuRowMapper` · `FeishuDateParser` · `FeishuPlatformNormalizer` · `FeishuKolDraft`。逻辑移植自 legacy `lib/feishu/sync-kols.ts`；`FeishuStageMapperTest` + `FeishuRowMapperTest` 等单测覆盖 §6 全表 + 行解析；`mvn -pl maildesk-application -am verify` BUILD SUCCESS。SQL 验收脚本留给 P2-T09。

#### P2-T03 — `FeishuSyncService` upsert KOL ✅

> **完成（2026-07-01）**：`FeishuSyncService` 编排只读 Sheet 拉取 + `FeishuSheetFilter` 近月 tab 过滤 + `mergeKey` 去重 + dryRun；`FeishuKolUpsertService` 按 `(email, feishu_operator_name)` 查找 upsert（200 行/chunk 独立事务），保护 `source=manual` 不被覆盖、stage null 不覆盖现有阶段、已有 owner 不被改写；同步时按 profile `feishu_operator_name` 匹配 owner。`FeishuClient` 新增 `configuredKolAppToken()`。9 项单测；`mvn -pl maildesk-application,maildesk-api -am verify` BUILD SUCCESS。HTTP 触发留给 P2-T05。

#### P2-T04 — `feishu_operator_name` 保存后自动归属 ✅

> **完成（2026-07-01）**：`TeamApplicationService.assignKolsByOperatorName`（`owner_user_id IS NULL` + 运营名归一化匹配）；`ProfileApplicationService.updateOwnProfile` 保存 profile 后自动调用；`PATCH /team/profile` 响应改为 `TeamProfileUpdateResponse { profile, kolsAssigned }`；OpenAPI 同步。F-AUTH-05 ✅（audit log 待 P5-T13）。

#### P2-T05 — `POST /api/v1/sync/feishu` + 进度 + 前端按钮 ✅

> **完成（2026-07-01）**：`SyncController`（`POST /api/v1/sync/feishu` → 202 · `GET /api/v1/sync/feishu/status`）；`FeishuSyncApplicationService` 内存进度 + 并发互斥；`FeishuSyncStatusDto`；工作台 `FeishuSyncButton` 接入 `headerActions`；`lib/api-client/sync.feishuStatus()` + `pnpm gen:api`。`mvn -pl maildesk-api -am verify` + `pnpm typecheck` 绿。

#### P2-T06 — Worker `FeishuDeltaSyncJob` ✅

> **完成（2026-07-01）**：`maildesk-infrastructure/redis/RedisDistributedLock`（SET NX + Lua 释放）；`maildesk-worker/feishu/FeishuDeltaSyncJob`（cron `0 */30 * * * *`、max-records 50、lock-ttl 25m、`TenantContext` 绑定默认租户）；`WorkerSchedulingConfig` + `WorkerProperties`；`FeishuSyncOptions.deltaBatch(int)`；worker `application.yml` 接 Redis + `TOKEN_ENCRYPTION_KEY`。P2-T08 将锁 key 统一为 `FeishuSyncLockKeys.SYNC`。`mvn -pl maildesk-worker -am verify` BUILD SUCCESS。

#### P2-T08 — 飞书全量回填 CLI ✅

> **完成（2026-07-01）**：`FeishuBackfillRunner`（`@Profile("backfill")` · `CommandLineRunner` · 跑完 `System.exit`）；`BackfillProperties` + `application-backfill.yml`（默认 `recent-months=0` 全 tab · 禁用 delta job）；`FeishuSyncOptions.backfill(recentMonths, dryRun)`；共享 `FeishuSyncLockKeys.SYNC` Redis 锁（TTL 60m）。用法：`mvn -pl maildesk-worker spring-boot:run -Dspring-boot.run.profiles=backfill`。

#### P2-T09 — 阶段映射 SQL 验收脚本 ✅

> **完成（2026-07-01）**：`kol-mail-desk-v2-docs/scripts/feishu-stage-mapping-audit.sql` — Part 1 fixture diff（SQL CASE 镜像 `FeishuStageMapper` · 期望 0 mismatch）；Part 2 飞书来源 KOL 阶段分布 + 9 阶段漏斗覆盖；Part 3 遗留 `replied` 异常行。用法：`psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/feishu-stage-mapping-audit.sql`。

#### P2-T07 — 飞书严格只读 ArchUnit 守护 ✅

> **完成（2026-06-30）**：`maildesk-api/src/test/.../FeishuReadOnlyArchitectureTest`（ArchUnit：禁 `com.lark.oapi`/`com.larksuite` SDK；`application`/`api`/`worker` 禁直接依赖 `integration.feishu` 实现类）；`maildesk-integration` 新增 `FeishuWriteApiGuard` + `FeishuReadOnlySourceTest`（扫描 `integration/feishu` 源码，禁写 HTTP 方法与 batch 写 API 路径，POST 白名单仅 `tenant_access_token/internal`）。全仓 ArchUnit 放在 api 模块测试以避免 domain↔integration Maven 循环依赖。
>
> **验收**：F-STAGE-04 ✅ · `mvn -pl maildesk-api,maildesk-integration -am verify` 绿

---

## Phase 3 — Gmail 同步（3～4 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P3-T01 | `GmailClient` 封装（messages.list / history.list / get full） | integration/gmail | 1.5d | ✅ |
| P3-T02 | `integration_credentials` 表 + AES-256 加密存取 | infrastructure | 1d | ✅ |
| P3-T03 | OAuth token 刷新 + 失效检测 | application | 1d | ✅ |
| P3-T04 | 「重新授权 Gmail」流程（前端 + 后端 redirect） | api + web | 1d | ✅ |
| P3-T05 | `GmailSyncService.incremental`（history.list + 2 天 safety net） | application | 2d | ✅ |
| P3-T06 | `GmailSyncService.history`（messages.list + pageToken 续传，并发 4） | application | 2d | ✅ |
| P3-T07 | `persistGmailSync`：飞书达人过滤 + 已读规则 + reply_resolved 清理 | application | 2d | ✅ |
| P3-T08 | `POST /api/v1/sync/gmail`（mode、pageToken）+ 前端 button | api + web | 1d | ✅ |
| P3-T09 | Worker `GmailIncrementalSyncJob` **每 5 分钟** | worker | 1d | ✅ |
| P3-T10 | Gmail 同步集成测试（录制 fixture，无需真实账号） | application test | 1.5d | ✅ |

**Phase 3 合计：~14 人日**

---

## Phase 4 — Spring AI（2 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P4-T01 | Spring AI starter + 多供应商配置（Moonshot + DeepSeek，`AiProviderProperties`/`AiModelRouter` + 主备 fallback，见 ADR-007） | ai | 1.5d | ✅ |
| P4-T02 | Prompt 模板从旧 `lib/ai/prompts.ts` 迁到 `resources/prompts/*.st` | ai | 1d | ✅ |
| P4-T03 | `AiService.classifyEmail`（8k 模型 + JSON schema 严格输出，**不含 `body_zh`**） | ai | 1.5d | ✅ |
| P4-T04 | `AiService.generateReplyDraft`（128k） | ai | 1d | ✅ |
| P4-T05 | `AiService.checkDraft`（8k） | ai | 1d | ✅ |
| P4-T06 | `AiService.translateText`（**默认 8k，超长升级 32k**，按需触发） | ai | 1d | ✅ |
| P4-T07 | 降级 fallback（无 Key / 401 / 余额不足 → 邮件仍入库，UI 显示「AI 失败」） | ai + application | 1d | ✅ |
| P4-T08 | Gmail 同步链路接 AI（新邮件触发**轻量**分类，已存在邮件跳过，**不做全文翻译**） | application | 1d | ✅ |
| P4-T09 | 「重新分析」按钮 API（手动触发对单封邮件再次 AI） | api + web | 0.5d | ✅ |
| P4-T10 | `ai_usage_log` 表 + 记录 token / 耗时 / 成本估算 | infrastructure | 1d | ✅ |

**Phase 4 合计：~10.5 人日**

> **成本设计结论（2026-07-01 讨论定稿，详见 `02-backend-design.md` §2.8「成本设计」）**：
> 1. `classifyEmail` 去掉 `body_zh` 全文翻译字段，只做轻量分类；Gmail 同步不再对每封邮件做全文翻译。
> 2. 邮件正文中译改为「按需点击触发」，复用旧版 `EmailBodyViewer` 的「翻译成中文」按钮 + `POST /api/v1/ai/translate`，不新增懒加载/预取机制，不依赖浏览器自带翻译。
> 3. 翻译不引入百度翻译 / 有道翻译等第三方 MT API：按当前报价核算，`moonshot-v1-8k` 单封成本（≈¥0.02）低于专用翻译 API（≈¥0.08~0.09/百万字符计费），且省去第三方凭证/降级/审计路径。
> 4. 翻译类「输出主导型」任务优先用 `v1-8k`/`v1-32k`（输入输出同价 ¥12/¥24 每百万 token），不用新款 `kimi-k2.x`（输出单价 ¥20~27/百万 token 明显更高）；`generateReplyDraft` 因需完整历史上下文仍用 `128k`。
> 5. outbound 邮件是否需要完整 AI 分类留待 P4-T03 实现时评估，未定论。
>
> **多供应商结论（2026-07-01 讨论定稿，详见 [`ADR-007`](./decisions/ADR-007-ai-multi-provider.md)）**：
> 1. 同时接入 Moonshot（Kimi）+ DeepSeek，均为 OpenAI 兼容协议，复用同一套 `spring-ai-openai` 客户端，靠 `AiModelRouter` 按能力选供应商，不新增依赖。
> 2. 切换供应商 = 改 `AI_DEFAULT_PROVIDER` 环境变量（或单个能力的 `provider` 配置）+ 填好对应 `*_API_KEY`，重启生效，不改代码。
> 3. 主供应商调用失败自动 fallback 到备用供应商，仍失败才走本地 heuristic 兜底（三级链路）。
> 4. DeepSeek 用 `deepseek-v4-flash`/`deepseek-v4-pro`（旧别名 2026-07-24 停用），输出单价 ¥2/百万 token，远低于 `moonshot-v1-8k` 的 ¥12/百万 token，是否切默认 provider 需先做人工质量抽样，不直接因为便宜就换默认值。
> 5. `ai_usage_log`（P4-T10）新增 `provider` 列以便按供应商拆分成本/成功率数据。

---

## Phase 5 — 写操作与发信（3 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P5-T01 | KOL 改名（仅工作台显示名） | api + application | 0.5d | ✅ |
| P5-T02 | KOL 阶段人工校准 | api + application | 0.5d | ✅ |
| P5-T03 | 标记/取消「无需回复」 | api + application | 0.5d | ✅ |
| P5-T04 | 邮件标记已读 / 未读 | api + application | 0.5d | ✅ |
| P5-T05 | 邮件删除（软删） | api + application | 0.5d | ✅ |
| P5-T06 | Gmail 发信单发（multipart/alternative + CC + 富文本 HTML） | integration/gmail + application | 2d | ✅ |
| P5-T07 | 批量跟进 `POST /api/v1/gmail/batch-send`（串行限流，每封独立记录） | application | 1.5d | ✅ |
| P5-T08 | 发信成功后写 outbound `emails` + 更新 `kol.last_outbound_at` + 模板 used_count++ | application | 1d | ✅ |
| P5-T09 | 模板 CRUD + 变量替换 | api + application | 1.5d | ✅ |
| P5-T10 | Team 编辑资料（角色 / mentor / 飞书运营名） | api + application | 0.5d | ✅ |
| P5-T11 | Team 标记离职（Leader 权限）→ 名下 KOL 进入团队池 | api + application | 1d | ✅ |
| P5-T12 | Team 池分配 KOL（Leader 权限） | api + application | 1d | ✅ |
| P5-T13 | 审计 `@AuditAction` + AOP 切面（所有写操作织入 `actions` 表） | application | 1.5d | ✅ |
| P5-T14 | 前端 `DraftSendPanel` 全功能（富文本 + CC + 模板插入 + 定时） | web | 2.5d | ✅ |
| P5-T15 | 前端 `KolNameEditor` / `KolStageEditor` / `ReplyResolvedButton` 接 API | web | 1d | ✅ |
| P5-T16 | 前端 `MarkEmailReadButton` / `AutoMarkRead` / `DeleteEmailButton` 接 API | web | 1d | ✅ |
| P5-T17 | 前端 `TemplateLibrary` CRUD | web | 1d | ✅ |
| P5-T18 | 前端 `BatchFollowupButton` 接 API（含进度反馈） | web | 1d | ✅ |
| P5-T19 | 前端 Team 页面 + `AssignPanel` 接 API | web | 1d | ✅ |
| P5-T20 | 真实 Gmail 冒烟（自发自收 + CC + 富文本回读） | qa | 0.5d | ✅ |

**Phase 5 合计：~20 人日**

#### P5-T20 — 真实 Gmail 冒烟 ✅

> **完成（2026-07-03）**：`maildesk-integration` 新增 `GmailSendSmokeTest` + `GmailSmokeEnv`（`@EnabledIf` 门禁，缺 env 静默跳过）；验证 send → getMessage 回读 To/Cc/HTML/plain；runbook [`scripts/gmail-send-smoke.md`](../scripts/gmail-send-smoke.md)；`06-testing.md` §2.3 引用。`mvn -pl maildesk-integration verify` 绿（无 env 时 smoke skipped）。

---

## Phase 6 — 定时邮件 + 生产化（2 周）

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P6-T01 | `scheduled_emails` 状态机（scheduled / processing / sent / failed / cancelled） | domain | 0.5d | ✅ |
| P6-T02 | 定时邮件 CRUD + 发送前取消 | api + application | 1d | ✅ |
| P6-T03 | Worker `ScheduledEmailDispatchJob` 每分钟原子认领（`UPDATE ... RETURNING`） | worker | 1.5d | ✅ |
| P6-T04 | 失败重试 ≤3 次，指数退避；超过停止 + UI 显示 failed | worker | 1d | ✅ |
| P6-T05 | 富文本 `english_body_html` 字段保留 + 发送 | application + integration/gmail | 0.5d | ✅ |
| P6-T06 | Docker 镜像（API + Worker 各一）+ multi-stage Dockerfile | ops | 1d | ✅ |
| P6-T07 | K8s manifests / Helm chart | ops | 2d | ✅ |
| P6-T08 | OpenTelemetry + Prometheus + Grafana dashboard（同步耗时 / AI 失败率 / Worker lag） | ops | 2d | ✅ |
| P6-T09 | 监控告警规则（Gmail 同步失败 > 阈值 / AI 失败率 > 10% / Worker lag > 5min） | ops | 1d | ✅ |
| P6-T10 | 数据迁移脚本（旧 Supabase → 新 PG），含 diff 校验 | ops/scripts | 3d | ✅ |
| P6-T11 | 双跑 + 切流方案演练（dry-run） | ops | 1d | ✅ |
| P6-T12 | 回滚预案 + Runbook | ops | 0.5d | ✅ |
| P6-T13 | 生产环境密钥进 Secrets Manager（不写 yml） | ops | 0.5d | ✅ |

**Phase 6 合计：~15.5 人日**

#### P6-T01～T03 — 定时邮件状态机 + 派发 ✅

> **完成（2026-07-03）**：
> - **T01**：`ScheduledEmailStatus` enum + `ScheduledEmailStateMachine`（cancel / claim 规则）
> - **T02**：`ScheduledEmailApplicationService` create/list/cancel 接状态机；取消仅 `scheduled` 态
> - **T03**：`ScheduledEmailMapper.claimDueBatch`（`FOR UPDATE SKIP LOCKED` + `RETURNING`）· `ScheduledEmailDispatchService` · Worker `ScheduledEmailDispatchJob`（cron 每分钟 · Redis 锁 · 复用 `GmailSendExecutor`）
> - 单测：`ScheduledEmailStateMachineTest` · `ScheduledEmailApplicationServiceCancelTest` · `ScheduledEmailDispatchServiceTest`
> - `mvn -pl maildesk-worker -am verify` BUILD SUCCESS

#### P6-T04～T05 — 重试退避 + 富文本派发 ✅

> **完成（2026-07-03）**：
> - **T04**：`ScheduledEmailRetryBackoff`（`2^(n-1)` 分钟）· `claimDueBatch` SQL 退避过滤 · 第 3 次失败终态 WARN 日志 · 前端「失败（将重试）/（已停止）」
> - **T05**：派发链路传 `englishBodyHtml` → `GmailSendExecutor` multipart · 单测 `dispatchClaimed_sendsHtmlBodyForMultipartAlternative` · 定时列表显示「富文本/CC」列

#### P6-T06 — Docker 镜像 ✅

> **完成（2026-07-03）**：
> - 根目录 **multi-stage `Dockerfile`**（`BUILD_MODULE=maildesk-api|maildesk-worker` · Maven 构建 · Temurin 21 JRE Alpine · 非 root · Actuator 健康检查）
> - **`.dockerignore`** · **`docker-compose.app.yml`**（叠加 `docker-compose.dev.yml` 本地全栈验证）
> - Worker **`management.server.port`** 默认 8081（Docker/K8s 探针）
> - CI **`docker-build`** job 构建双镜像（需 GitHub runner Docker）
> - 本机无 Docker → 镜像构建待 CI 实锤

#### P6-T07 — K8s / Helm ✅

> **完成（2026-07-03）**：
> - **`deploy/helm/maildesk/`** Helm chart：API + Worker Deployment/Service、可选 Ingress + API HPA、ServiceAccount、Secret 模板（`secrets.create=false` 默认，对接 External Secrets / P6-T13）
> - 环境变量对齐 `.env.example` / `application.yml`（DB/Redis/OAuth/飞书/AI 密钥经 Secret 注入）
> - Worker 默认 **1 副本** + 宽松 liveness（R6/R7）；探针 `/actuator/health`
> - **`deploy/k8s/README.md`** · `values-local.example.yaml` · CI **`helm-lint`** + `helm template` dry render
> - 本机无 Helm → chart 校验待 CI 实锤

#### P6-T08 — 可观测性 ✅

> **完成（2026-07-03）**：
> - **Micrometer + Prometheus**：`/actuator/prometheus` · 指标 `gmail.sync.duration` / `gmail.sync.failed` / `ai.invocation` / `ai.classify.tokens` / `scheduled_email.dispatch.lag_seconds`
> - **OpenTelemetry OTLP** tracing（`application-observability.yml` · 默认 10% 采样）
> - **Grafana dashboard** `deploy/grafana/dashboards/maildesk-overview.json` · 本地栈 `docker-compose.observability.yml`
> - Helm **ServiceMonitor** + Prometheus scrape annotations · 单测 `MaildeskMetricsTest` / `AiUsageMicrometerTest`

#### P6-T09 — 监控告警 ✅

> **完成（2026-07-03）**：
> - **`deploy/prometheus/alerts/maildesk.rules.yml`**：Gmail 15m≥3 失败 · AI 失败率 >10% · dispatch lag >300s · target down
> - **`docker-compose.observability.yml`** 挂载 alert rules · Helm **`PrometheusRule`**（`alerts.enabled`）

#### P6-T10 — 数据迁移 ✅

> **完成（2026-07-03）**：
> - **`kol-mail-desk-v2-docs/scripts/migration/`**：`migrate.sh` + dblink SQL（profiles → actions）· `diff.sh` 容差校验 + KOL 最新邮件零容差
> - **`migrate-google-credentials.sh`** + Worker `LegacyGoogleCredentialMigrator`（`spring.profiles.active=migration`）
> - Runbook：`scripts/migration/README.md` · 容差对齐 `06-testing.md § 七`

#### P6-T11 — 双跑 + 切流演练 ✅

> **完成（2026-07-03）**：
> - **`scripts/cutover/`**：`dual-run-drill.sh`（feature-parity + diff + health 门禁）· `README.md` 双跑架构
> - **`cutover-runbook.md`**：生产切流时间线、RACI、drill sign-off 模板
> - 交叉引用：`migration/README.md` · `deploy/k8s/README.md` · `06-testing.md §7` · `04-phases.md`

#### P6-T12 — 回滚 Runbook ✅

> **完成（2026-07-03）**：
> - **`scripts/cutover/rollback-runbook.md`**：决策矩阵、RTO/RPO、15min 回滚步骤、通信模板
> - 切流前失败 / 双跑 staging 失败分支；与 `07-risks.md` R8/R11 对齐

#### P6-T13 — 生产密钥 Secrets Manager ✅

> **完成（2026-07-03）**：
> - **`deploy/secrets/README.md`**：AWS/GCP SM 写入 · IRSA/WI · 轮换 · 验证
> - Helm **`external-secret.yaml`** + **`secret-store.yaml`** · **`values-prod.example.yaml`**
> - **`deploy/secrets/verify-k8s-secret.sh`** · CI **`guard-no-plaintext-secrets.sh`**
> - 默认 `secrets.create=false` · `externalSecrets.enabled=true` 生产路径

---

## Phase 7B — 看板 v1 Parity 补全（2～2.5 周）

> v1 看板可下钻 / 成员进度 / 平台分布 / 邮件动态等能力补回 v2。不含工作台侧栏「高优先级」（产品已用「未读」替代）。  
> 「停滞（≥3 天）」口径仅保留在团队页 `stalledKolCount`，看板 KPI 统一为「待回复」。

### 概览

| Ticket | 标题 | 模块 | 依赖 | 预估 | 状态 |
|--------|------|------|------|------|------|
| P7B-T01 | KPI 改名「待回复」+ 口径文档对齐 | docs + web | — | 0.25d | ✅ |
| P7B-T02 | 看板 API：成员视角 + 含实习生 rollup | backend + OpenAPI | — | 1.5d | ✅ |
| P7B-T03 | 看板 UI：视角栏 + 含实习生开关 | web | P7B-T02 | 0.5d | ✅ |
| P7B-T04 | 看板 API：达人明细列表（下钻数据源） | backend + OpenAPI | P7B-T02 | 2d | ✅ |
| P7B-T05 | KPI 可点击 + `detail` 路由状态 | web | P7B-T04 | 0.5d | ✅ |
| P7B-T06 | 下钻达人列表 UI + 跳转工作台 | web | P7B-T04, P7B-T05 | 1d | ✅ |
| P7B-T07 | Pipeline 阶段点击 → 下钻联动 | web | P7B-T05, P7B-T06 | 0.5d | ✅ |
| P7B-T08 | 看板 API：成员进度行 | backend + OpenAPI | P7B-T02, P7B-T04 | 1.5d | ✅ |
| P7B-T09 | 成员进度 UI（Members 区块） | web | P7B-T08 | 1d | ✅ |
| P7B-T10 | 平台分布（环形图 + 列表） | web + OpenAPI | P7B-T04 | 0.75d | ✅ |
| P7B-T11 | 最近邮件动态（16 条 + 跳工作台） | web + OpenAPI | P7B-T04 | 0.75d | ✅ |
| P7B-T12 | 时间窗：历史月份快捷 chip | backend + web | P7B-T02 | 0.5d | ✅ |
| P7B-T13 | 看板两栏布局壳 | web | P7B-T09~T11 | 0.5d | ✅ |
| P7B-T14 | E2E + feature-parity / BACKLOG 回填 | web + docs | P7B-T01~T13 | 1d | ✅ |

**Phase 7B 合计：~12.25 人日**

### 详细

#### P7B-T01 — KPI 改名「待回复」

- **模块**: `kol-mail-desk-v2-docs/specs/api-contract-v1.yaml` · `kol-mail-desk-v2-web/components/pages/BoardPage.tsx`
- **Feature**: `F-BOARD-KPI`
- **DoD**:
  - 看板 KPI 标签改为 **「待回复」**（去掉「/ 停滞」）
  - OpenAPI `BoardKpi.unrepliedKols` 描述对齐口径（非 3 天停滞）
  - `05-feature-parity.md` 同步
  - **不改** `BoardApplicationService.needsReply` 统计逻辑

#### P7B-T02 — 看板 API：成员视角 + 含实习生

- **模块**: `maildesk-application/.../board/` · `api-contract-v1.yaml`
- **Feature**: `F-BOARD-SCOPE`
- **依赖**: —
- **DoD**:
  - `GET /api/v1/board` 新增 `owner`（UUID 可选）、`includeInterns`（boolean，默认 true）
  - KPI / funnel / stageDistribution 随 scope 变化
  - 实习生 rollup 逻辑对齐 v1 `board-data.ts`
  - 单元测试 + OpenAPI 更新

#### P7B-T03 — 看板 UI：视角栏

- **模块**: `components/pages/BoardPage.tsx`
- **Feature**: `F-BOARD-SCOPE`
- **依赖**: P7B-T02
- **DoD**:
  - 顶栏「视角」：全部成员 + 各成员（显示名 + 角色）
  - 「含实习生 / 不含实习生」toggle；URL 持久化

#### P7B-T04 — 看板 API：达人明细列表

- **模块**: `BoardApplicationService` · OpenAPI
- **Feature**: `F-BOARD-DRILL`
- **依赖**: P7B-T02
- **DoD**:
  - 扩展 board 响应或新增 `GET /api/v1/board/kols`（契约定案）
  - 返回 scope + window 下达人列表（含 latestEmail 摘要字段）
  - 支持 `detail=kols|unreplied|unread` + 可选 `stage` 预筛
  - `detail=unreplied` 条数与 KPI `unrepliedKols` 一致

#### P7B-T05 — KPI 可点击 + detail 状态

- **Feature**: `F-BOARD-DRILL`
- **依赖**: P7B-T04
- **DoD**:
  - 总达人 / 待回复 / 未读邮件 KPI 可点击；选中高亮
  - URL `detail=kols|unreplied|unread`；「进入合作」不可点

#### P7B-T06 — 下钻达人列表 UI

- **Feature**: `F-BOARD-DRILL`
- **依赖**: P7B-T04, P7B-T05
- **DoD**:
  - 底部列表：姓名 / 邮箱 / 平台 / AI 摘要 / 优先级
  - 标题「待回复达人 · N」等；点击 → 工作台对应达人

#### P7B-T07 — Pipeline 阶段下钻

- **Feature**: `F-BOARD-DRILL` · `F-BOARD-PIPELINE`
- **依赖**: P7B-T05, P7B-T06
- **DoD**:
  - `BoardPipelinePanel` 链接 `detail=kols&stage={stage}` 可用
  - 列表标题「{阶段名} · 达人列表」

#### P7B-T08 — 看板 API：成员进度行

- **Feature**: `F-BOARD-MEMBERS`
- **依赖**: P7B-T02, P7B-T04
- **DoD**:
  - 响应 `members[]`：未读 / 待回复 / 总数 / stageCounts / coveredMemberIds
  - 成员行 `unreplied` = 待回复口径（非 stalled）

#### P7B-T09 — 成员进度 UI

- **Feature**: `F-BOARD-MEMBERS`
- **依赖**: P7B-T08
- **DoD**:
  - 「成员进度 / 成员明细」卡片 + 阶段分布条（迁 v1 StageBar）

#### P7B-T10 — 平台分布

- **Feature**: `F-BOARD-COMPOSITION`
- **依赖**: P7B-T04
- **DoD**:
  - 右侧 Donut + 平台列表；随 scope + window 变化

#### P7B-T11 — 最近邮件动态

- **Feature**: `F-BOARD-ACTIVITY`
- **依赖**: P7B-T04
- **DoD**:
  - 最近 16 条邮件动态；点击 → 工作台

#### P7B-T12 — 历史月份快捷 chip

- **Feature**: `F-BOARD-WINDOW`
- **依赖**: P7B-T02
- **DoD**:
  - 后端 `availableMonths[]`；时间栏最多 6 个 yyyy-MM 快捷 chip

#### P7B-T13 — 两栏布局壳

- **依赖**: P7B-T09~T11
- **DoD**:
  - 左：Pipeline + Members；右：平台 + 动态；下钻列表全宽底部

#### P7B-T14 — E2E + 文档回填

- **依赖**: P7B-T01~T13
- **DoD**:
  - Playwright：KPI 下钻 / Pipeline 点击 / 视角切换
  - `05-feature-parity.md` · `STATUS.md` Phase 7B 完成度

---

## Phase 8 — SaaS 增强（可选，4～6 周）

> 原 Phase 7，因看板 Parity 插入 Phase 7B 而顺延编号。

### 概览

| Ticket | 标题 | 模块 | 预估 |
|--------|------|------|------|
| P8-T01 | Gmail Push（Pub/Sub）+ Webhook 近实时同步 | integration/gmail + worker | 3d |
| P8-T02 | Gmail Watch 续订 Job（每天） | worker | 1d |
| P8-T03 | 全链路 `tenant_id` 验证 + RLS 启用 | infrastructure | 2d |
| P8-T04 | 平台管理后台（租户管理 / 配额 / 用量报表） | api + web | 5d |
| P8-T05 | 租户 onboarding 流程（邀请 → 创建租户 → 初始化 owner） | application + web | 3d |
| P8-T06 | OpenSearch 集成 + 全文搜索（达人 / 邮件 / AI 摘要） | infrastructure + api | 4d |
| P8-T07 | SSO（SAML / OIDC） | api | 4d |
| P8-T08 | Stripe 计费（可选） | api + web | 5d |

**Phase 8 合计：~27 人日（可选范围）**

---

## ticket 状态汇总

> 自动统计脚本（Phase 6 末期补）会扫描本文件，输出"未开始 / 进行中 / 完成"数字到 STATUS.md。

当前手工统计（D0）：

| Phase | 总数 | ✅ | 🔄 | ⬜ | 完成率 |
|-------|------|----|----|----|--------|
| P0 | 11 | 11 | 0 | 0 | 100% |
| P1 | 18 | 10 | 0 | 8 | 56% |
| P2 | 9 | 0 | 0 | 9 | 0% |
| P3 | 10 | 0 | 0 | 10 | 0% |
| P4 | 10 | 0 | 0 | 10 | 0% |
| P5 | 20 | 0 | 0 | 20 | 0% |
| P6 | 13 | 0 | 0 | 13 | 0% |
| P7B | 14 | 2 | 0 | 12 | 14% |
| P8 | 8 | 0 | 0 | 8 | 0% |
| **总计** | **113** | **20** | **1** | **92** | **18%** |

---

## 协作约定

1. **挑选 ticket**：从 STATUS.md 的"当前活跃 ticket"接续；若该 ticket 已完成，从同 Phase 中"⬜ 未开始且依赖已满足"中选下一个
2. **ticket 进入 🔄**：在本文件标记 🔄 + 更新 STATUS.md "当前活跃 ticket"
3. **ticket 完成 ✅**：本文件 + STATUS.md + 05-feature-parity.md 三处同步更新，commit 时一并纳入
4. **拆 ticket**：单 ticket 超过 2 人日的，先拆为子 ticket（P{n}-T{n}.{sub}）再做
5. **跨 Phase 影响**：若某 ticket 暴露出会影响后续 Phase 的设计问题，先停下开 ADR 评审，不要硬塞
6. **🚫 决定不做**：必须在 ticket 项注明原因，并在 `07-risks.md` 评估遗留风险
