# 项目当前状态（Single Source of Truth）

> **每次新会话开头必读，每次完成 ticket 必更新。**
> 该文件是 Agent 跨会话续接的唯一依据。任何与本文件冲突的"猜测"都应作废。

---

## 元信息

| 字段 | 值 |
|------|-----|
| 最后更新 | 2026-07-08（Phase 7B 完成 · P7B-T12~T14 月份 chip / 布局壳 / E2E） |
| 更新者 | Agent — 看板 v1 parity Phase 7B |
| Git 提交 | 三仓库首次 commit 已完成并推送到 `github.com/Cavan-cloud/kol-mail-desk-v2-{backend,web,docs}` main 分支 |
| 项目相对天数 | D0（计划期） |
| 工作模式 | **multi-root workspace**：`~/code/maildesk-v2.code-workspace`（已创建） |

---

## 当前 Phase

**Phase 7B — 看板 v1 Parity 补全（14/14）✅ 已完成**

Phase 0～6 已完成。详见 [`BACKLOG.md` § Phase 7B](./BACKLOG.md#phase-7b--看板-v1-parity-补全22-25-周)。

### Phase 7B 完成度

| Ticket | 描述 | 状态 |
|--------|------|------|
| P7B-T01 | KPI 改名「待回复」+ 口径文档对齐 | ✅ |
| P7B-T02 | 看板 API：成员视角 + 含实习生 rollup | ✅ |
| P7B-T03 | 看板 UI：视角栏 + 含实习生开关 | ✅ |
| P7B-T04 | 看板 API：达人明细列表（下钻数据源） | ✅ |
| P7B-T05 | KPI 可点击 + `detail` 路由状态 | ✅ |
| P7B-T06 | 下钻达人列表 UI + 跳转工作台 | ✅ |
| P7B-T07 | Pipeline 阶段点击 → 下钻联动 | ✅ |
| P7B-T08 | 看板 API：成员进度行 | ✅ |
| P7B-T09 | 成员进度 UI（Members 区块） | ✅ |
| P7B-T10 | 平台分布（环形图 + 列表） | ✅ |
| P7B-T11 | 最近邮件动态（16 条 + 跳工作台） | ✅ |
| P7B-T12 | 时间窗：历史月份快捷 chip | ✅ |
| P7B-T13 | 看板两栏布局壳 | ✅ |
| P7B-T14 | E2E + feature-parity / BACKLOG 回填 | ✅ |

完成进度：**14 / 14 = 100%**

### Phase 6 完成度（已完成）

| Ticket | 描述 | 状态 |
|--------|------|------|
| P6-T01 | `scheduled_emails` 状态机（scheduled / processing / sent / failed / cancelled） | ✅ |
| P6-T02 | 定时邮件 CRUD + 发送前取消 | ✅ |
| P6-T03 | Worker `ScheduledEmailDispatchJob` 每分钟原子认领 | ✅ |
| P6-T04 | 失败重试 ≤3 次 + 指数退避 + UI failed 展示 | ✅ |
| P6-T05 | 富文本 `english_body_html` 保留 + multipart 发送 | ✅ |
| P6-T06 | Docker 镜像（API + Worker · multi-stage Dockerfile · CI docker-build） | ✅ |
| P6-T07 | K8s / Helm chart（API + Worker Deployment · Ingress/HPA · CI helm-lint） | ✅ |
| P6-T08 | OpenTelemetry + Prometheus + Grafana dashboard | ✅ |
| P6-T09 | Prometheus 告警规则（Gmail / AI / dispatch lag） | ✅ |
| P6-T10 | Supabase → PG 迁移脚本 + diff 校验 + Google token 加密迁移 | ✅ |
| P6-T11 | 双跑 + 切流方案演练（dry-run · `scripts/cutover/`） | ✅ |
| P6-T12 | 回滚预案 + Runbook | ✅ |
| P6-T13 | 生产密钥 External Secrets + Secrets Manager Runbook | ✅ |

完成进度：**13 / 13 = 100%** 🎉

### Phase 5 完成度（已完成）

| Ticket | 描述 | 状态 |
|--------|------|------|
| P5-T01 | KOL 改名（`PATCH /api/v1/kols/{kolId}` · `name` + `name_overridden` · 飞书 sync 跳过已改名） | ✅ |
| P5-T02 | KOL 阶段人工校准（`PATCH` `stage` + `stage_override` · 飞书 sync 跳过） | ✅ |
| P5-T13 | 审计 `@AuditAction` + `AuditLogService` + AOP 切面（`actions` 表 append-only） | ✅ |

| P5-T03 | 标记/取消「无需回复」（`PATCH` `replyResolved` + 审计） | ✅ |
| P5-T04 | 邮件标记已读/未读（`PATCH /emails/{id}` + `read_at` + 审计） | ✅ |
| P5-T05 | 邮件软删（`DELETE /emails/{id}` · 无邮件时删 KOL · owner/leader 权限） | ✅ |
| P5-T06 | Gmail 单发（`multipart/alternative` + CC + HTML · `POST /gmail/send`） | ✅ |
| P5-T07 | 批量跟进（`POST /gmail/batch-send` · 串行 1.2s · 独立事务） | ✅ |
| P5-T08 | 发信落库（outbound emails + `last_outbound_at` + 模板 `used_count`） | ✅ |
| P5-T09 | 模板 CRUD + `TemplateRenderService` 变量替换 | ✅ |
| P5-T10 | Team 编辑资料（`PATCH /team/profile` · 前端 Team 页 · Leader 守卫） | ✅ |
| P5-T11 | Team 标记离职（`POST /team/depart/{userId}` · 名下 active KOL → orphaned · 审计） | ✅ |
| P5-T12 | Team 池分配 KOL（`POST /kols/assign` · 仅 orphaned · Leader · 审计） | ✅ |
| P5-T19 | 前端 Team 页 + `AssignPanel` + `TeamMemberActions` 接 API | ✅ |
| P5-T14 | 前端 `DraftSendPanel` 全功能 + `AiController` + 定时邮件创建 API | ✅ |
| P5-T15 | 前端 `KolNameEditor` / `KolStageEditor` / `ReplyResolvedButton` 接 API | ✅ |
| P5-T16 | 前端 `MarkEmailReadButton` / `AutoMarkRead` / `DeleteEmailButton` 接 API | ✅ |
| P5-T17 | 前端 `TemplateLibrary` CRUD | ✅ |
| P5-T18 | 前端 `BatchFollowupButton` 接 API（含进度反馈） | ✅ |
| P5-T20 | 真实 Gmail 冒烟（`GmailSendSmokeTest` + runbook） | ✅ |

完成进度：**20 / 20 = 100%** 🎉

### Phase 4 完成度（已完成）

| Ticket | 描述 | 状态 |
|--------|------|------|
| P4-T01 | Spring AI starter + 多供应商配置（Moonshot + DeepSeek，`AiModelRouter` + 主备 fallback，ADR-007） | ✅ |
| P4-T02 | Prompt 模板从旧 `lib/ai/prompts.ts` 迁到 `resources/prompts/*.st` | ✅ |
| P4-T03 | `AiService.classifyEmail`（8k + JSON schema，**不含 `body_zh`**） | ✅ |
| P4-T04 | `AiService.generateReplyDraft`（128k） | ✅ |
| P4-T05 | `AiService.checkDraft`（8k） | ✅ |
| P4-T06 | `AiService.translateText`（默认 8k，按需触发） | ✅ |
| P4-T07 | 降级 fallback（无 Key / 401 / 余额不足 → 邮件仍入库） | ✅ |
| P4-T08 | Gmail 同步链路接 AI（轻量分类，不做全文翻译） | ✅ |
| P4-T09 | 「重新分析」按钮 API | ✅ |
| P4-T10 | `ai_usage_log` 表 + token / 耗时 / 成本估算 | ✅ |

完成进度：**10 / 10 = 100%** 🎉

### Phase 3 完成度（已完成）

| Ticket | 描述 | 状态 |
|--------|------|------|
| P3-T01 | `GmailClient`（messages.list / history.list / get full） | ✅ |
| P3-T02 | `integration_credentials` + AES-256 加密存取 | ✅ |
| P3-T03 | OAuth token 刷新 + 失效检测 | ✅ |
| P3-T04 | 「重新授权 Gmail」流程（`/me.gmailAuthorized` + 顶栏 banner + 同步失败引导） | ✅ |
| P3-T05 | `GmailSyncService.incremental`（history.list + 2 天 safety net） | ✅ |
| P3-T06 | `GmailSyncService.history`（pageToken 续传，并发 4） | ✅ |
| P3-T07 | `persistGmailSync`：飞书过滤 + 已读规则 + reply_resolved | ✅ |
| P3-T08 | `POST /api/v1/sync/gmail` + `GmailSyncButton` 工作台接入 | ✅ |
| P3-T09 | Worker `GmailIncrementalSyncJob` **每 5 分钟** | ✅ |
| P3-T10 | Gmail 同步 fixture / 单元测试套件 | ✅ |

完成进度：**10 / 10 = 100%** 🎉

### Phase 2 完成度

| Ticket | 描述 | 状态 |
|--------|------|------|
| P2-T01 | `FeishuClient`（拉 Sheet / Bitable） | ✅ |
| P2-T02 | 飞书字段映射 + 阶段映射（10 阶段 v3.3 §6） | ✅ |
| P2-T03 | `FeishuSyncService` upsert KOL | ✅ |
| P2-T04 | `feishu_operator_name` 保存后自动归属 | ✅ |
| P2-T05 | `POST /api/v1/sync/feishu` + 进度 + 前端按钮 | ✅ |
| P2-T06 | Worker `FeishuDeltaSyncJob` | ✅ |
| P2-T07 | 飞书严格只读 ArchUnit 守护 | ✅ |
| P2-T08 | 飞书全量回填 CLI | ✅ |
| P2-T09 | 阶段映射 SQL 验收脚本 | ✅ |

完成进度：**9 / 9 = 100%** 🎉

### Phase 1 完成度

| Ticket | 描述 | 状态 |
|--------|------|------|
| P1-T01 | Maven 父 POM + 8 子模块骨架 + ArchUnit 守护 | ✅ |
| P1-T02 | Flyway 基础迁移 V1（V1~V13，13 张表 + 5 枚举 + 多租户/审计列） | ✅ ⚠️ |
| P1-T03 | MyBatis-Plus 全局配置（4 拦截器 + AuditFiller + TenantContext + 3 TypeHandler + 示例 DO/Mapper） | ✅ ⚠️ |
| P1-T04 | Spring Security + Google OAuth2 登录（AES-256-GCM token encryption + Redis 会话 + `/me`/`/auth/logout`/`/gmail/authorize`） | ✅ ⚠️ |
| P1-T11 | OpenAPI 契约填充 Phase 1 全部端点（28 path / 47 schema） | ✅ |
| P1-T12 | Next.js 15 项目初始化 + Tailwind / globals.css 迁入 | ✅ |
| P1-T14 | `lib/api-client/`（openapi-typescript + openapi-fetch + 11 子域 + 单元测试） | ✅ |
| P1-T18 | dev seed 数据脚本（V14 google_sub + 6 个 dev-*.sql + `SeedRunner@Profile("seed")` + `SeedRunnerIT`） | ✅ ⚠️ |
| P1-T13 | 组件迁入（24 白名单 + AutoMarkRead，共 25 个；`api-client` 替换旧 fetch） | ✅ |
| P1-T05 | `profiles` 落库 + 首次资料完善（PATCH /team/profile + OAuth pending_approval） | ✅ |
| P1-T06 | `WorkbenchController` + `KolController` GET（列表 / 侧栏统计 / 详情 + 邮件时间线） | ✅ |
| P1-T07 | `BoardController` GET（KPI + 漏斗 + 阶段分布 + 时间窗） | ✅ |
| P1-T08 | `TeamController` GET `/team/members`（成员列表 + 指标） | ✅ |
| P1-T09 | `TemplateController` GET（当前用户模板列表） | ✅ |
| P1-T10 | `ScheduledEmailController` GET（定时邮件列表） | ✅ |
| P1-T15 | 6 页面壳接 api-client（工作台 / 看板 / 团队 / 模板 / 定时 / 登录）+ `/onboarding` | ✅ |
| P1-T16 | 删除旧 lib 占位 + ESLint / Vitest legacy import 守护 | ✅ |
| P1-T17 | E2E smoke（Playwright @smoke：登录 / 工作台 / 看板） | ✅ |

完成进度：**18 / 18 = 100%**

> ⚠️ P1-T02 / P1-T03 / P1-T18：代码 + `mvn verify` + ArchUnit 全绿，但 `FlywayMigrationIT` / `MyBatisPlusConfigIT` / `SeedRunnerIT` 因本机无 Docker 优雅跳过（P1-T18 用类级 `@EnabledIf("isDockerAvailable")` gate，避免 SpringExtension 在无 Docker 时启动） → 需在带 Docker 的 CI 实锤。
>
> ⚠️ P1-T04 安全提示：当前 `application.yml` 走 `${TOKEN_ENCRYPTION_KEY:base64-test-key-32-bytes-for-local-dev-environment-only}` 默认值仅供本机起服，**生产**必须显式注入 32 字节 base64 主密钥；同理 `${GOOGLE_OAUTH_CLIENT_ID}` / `${GOOGLE_OAUTH_CLIENT_SECRET}` 必须从外部传入。`TokenEncryptionServiceTest` 单测通过；OAuth 端到端集成测试待 Gmail 同步 ticket 联调。
>
> 📌 P1-T14 契约观察（待 Phase 1 推进时回校 OpenAPI，不阻塞）：
> 1. AI 响应使用 `{result}` 信封（前端已透明解包）
> 2. `GmailSyncRequest.mode` 因 schema 默认值导致类型 required（不影响实际调用）
> 3. 第 3 项见 [T14 完成报告](5209e1d8-2cd1-4ea5-8ded-e931fc4f878d)

---

### Phase 0 完成度（已完成）

| Ticket | 描述 | 状态 |
|--------|------|------|
| P0-T01 | 三仓库目录建立 | ✅ |
| P0-T02 | AGENTS.md（后端、前端） | ✅ |
| P0-T03 | `.cursor/rules/`（全局 + 后端 + 前端） | ✅ |
| P0-T04 | `harness/risk-tiers.json` | ✅ |
| P0-T05 | specs 中文化（00～07） | ✅ |
| P0-T06 | 决策记录 ADR-001～006 | ✅（含 ADR-006 ORM 反转） |
| P0-T07 | 后端 `docs/standards/` 三件套 | ✅（项目结构 / 编码 / 流程） |
| P0-T08 | 执行层文档（STATUS / BACKLOG / SETUP + 功能勾选 + mdc 协议 + phases 对账） | ✅ |
| P0-T09 | 旧仓库标记「只读参考」 | ✅ |
| P0-T10 | CI 模板（GitHub Actions 草案） | ✅ |
| P0-T11 | 三仓库 `git init` + 首次提交 + 远端 `Cavan-cloud/*` + push + `docker-compose.dev.yml` + `.env.example` | ✅ |

完成进度：**11 / 11 = 100%** 🎉

---

## 当前活跃 ticket

**无 — Phase 7B 已完成，等待人工挑选 Phase 8 ticket**

---

## 阻塞项

| 阻塞 | 影响 | 等待 |
|------|------|------|
| staging（kolmail.top）未部署 | F-AUTH-01/03 staging 复验 · cutover drill | 部署 api/app 子域 + GCP OAuth 回调 |
| 本地未启 Worker | Gmail 5min 增量 · 飞书 30min delta · 定时邮件派发 | 另开 terminal `mvn -pl maildesk-worker spring-boot:run` |

---

## 近期 bugfix 记录

| 日期 | 问题 | 根因 | 修复 |
|------|------|------|------|
| 2026-07-18 | 工作台报价栏多为「待确认」，且无最终报价栏 | ① 表头 `报价` contains 可能误伤/`品牌报价` 空单元格未回退 `KOL报价($)`；② 多 tab `putIfAbsent` 先到空价后丢区域表有价行；③ 前端只读 `brandQuote` 且 `finalCooperationPrice==null` 时不渲染 | 后端：单元格级报价回退 + `最终报价` 候选 + `preferRicherPrices` 合并；前端：报价 fallback `agreedPrice`，最终合作价格栏常显（空为待确认）。部署后需再跑飞书全量同步回填 |

| 2026-07-04 | 真实 Google 账号登录后被弹回 `/login`，重试多次都进不去 | Spring Security 默认把 `oauth2Login` 成功后的身份持久化进 `JSESSIONID` HttpSession，后续请求被 `SecurityContextHolderFilter` 恢复的陈旧身份抢占，导致 `SessionCookieAuthenticationFilter`（Redis `MAILDESK_SESSION`）被跳过 → 401 | `SecurityConfig` 增加 `securityContextRepository(new NullSecurityContextRepository())`，禁止 HttpSession 读写认证上下文；详见 `BACKLOG.md` P1-T04 |
| 2026-07-04 | `GET /team/members`（查看团队成员）与 `GET /workbench?view=pool`（团队池达人列表）均 500：`PSQLException: operator does not exist: kol_status = character varying` | `kols.status` 是 PG 原生 `kol_status` ENUM，但 `KolDO.status` 一直是裸 `String` 字段（不像 `stage` 有 `KolStageTypeHandler`），MyBatis-Plus 按参数运行时类型（`String`）分派到默认 `StringTypeHandler`，绑定为 `varchar`，导致 `.in(KolDO::getStatus, "unassigned", "orphaned")` 这类 wrapper 查询在 PG 侧报枚举/varchar 无匹配 operator | 新增 `common/enums/KolStatus` + `common/typehandler/KolStatusTypeHandler`（仿 `KolStage` 模式），`KolDO.status` 改为 `KolStatus` 类型并注册进 `MyBatisPlusConfig`；同步改造 `TeamApplicationService` / `WorkbenchApplicationService` / `BoardApplicationService` / `FeishuKolUpsertService` / `GmailPersistService` / `EntityMappers` 及相关测试的字符串字面量为枚举；本地起 API + 手工构造 Redis session 验证两接口均恢复 200 |
| 2026-07-04 | 工作台顶栏「同步飞书」按钮与「增量同步/历史同步」不在同一行 | `FeishuSyncButton` 外层用 `flex-col` 包裹，idle 态下按钮下方恒定渲染一行提示文案（「只读拉取飞书 Sheet，不会修改飞书数据」），撑高了整个组件，导致 `headerActions` 里和单行的 `GmailSyncButton`/`BatchFollowupButton` 对不齐（曾误判并改动按钮配色，已撤回：按钮保留原 `primary-island-button` 强调色不变） | `components/sync/FeishuSyncButton.tsx` 去掉外层 `flex-col` + 底部 `<p>` 提示行，改成与其余按钮一致的单行 `flex flex-wrap items-center` 布局，只读说明移入 `title` tooltip；按钮本身颜色/高度保持 `primary-island-button h-10` 不变 |
| 2026-07-04 | 新用户 onboarding 保存后仍停留在资料页 | 保存 profile 后未 invalidate `me` 缓存，`RequireAuth` 仍读到 `pending_approval` 跳回 onboarding | `app/onboarding/page.tsx` 保存成功后 `queryClient.setQueryData(queryKeys.me, result.profile)` |
| 2026-07-04 | 飞书同步 500：`primary_platform` PG enum 写入失败 | `KolDO.primary_platform` 裸 String，MyBatis 无法绑定 `platform` ENUM | 新增 `Platform` 枚举 + `PlatformTypeHandler` |
| 2026-07-04 | Gmail 同步 `transport error` | 本机无法直连 `gmail.googleapis.com` | 开代理/VPN；后端 JVM 也需能访问 Google |
| 2026-07-04 | 登录修复后工作台 / 团队页报 500：`operator does not exist: kol_status = character varying` | `KolStageTypeHandler`/`KolStatusTypeHandler`/`EmailDirectionTypeHandler`/`ActionTypeTypeHandler` 均继承 `PgEnumTypeHandler extends BaseTypeHandler`（未实现 `TypeReference`），`TypeHandlerRegistry.register(handler)` 单参重载无法反射出映射的 Java 类型，实际注册到了「无类型」桶。`@TableField(typeHandler=...)` 字段级注解仍能覆盖单表 INSERT/SELECT，但 `LambdaQueryWrapper.eq()/.in()` 直接传枚举常量构造 WHERE 条件时找不到该类型的 handler，退化成裸 VARCHAR 绑定，被 Postgres 枚举列拒绝 | `MyBatisPlusConfig` 改用显式 `registry.register(EnumClass.class, new XxxTypeHandler())` 重载（仿照已有的 `UuidTypeHandler` 写法）为四个枚举类型分别登记，同时覆盖字段映射与 Wrapper 条件绑定两条路径 |

---

## 下次会话起点（开新窗口时按此恢复）

0. **打开项目**：`cursor ~/code/maildesk-v2.code-workspace`（多 root，能同时看到 docs / backend / web / legacy）
1. **第一步**：`Read kol-mail-desk-v2-docs/specs/STATUS.md`（本文件）
2. **第二步**：
   - 若"当前活跃 ticket"已指定 → 直接读 BACKLOG.md 中该 ticket 的 DoD 后开干
   - 若为「无 — 等待人工挑选」→ 列出剩余 ticket，让用户选，**不要自作主张**
3. **第三步**：选定后把本文件的"当前活跃 ticket"字段更新成对应 ticket ID + 标 `🔄`
4. **第四步**：完成 ticket 后回填本文件 + `BACKLOG.md` 对应 ticket 勾选 + `05-feature-parity.md` 对应功能勾选（如关联）

如本文件指向的 ticket 已经 done（status mismatch），说明 STATUS 未及时更新，先核对 git log + BACKLOG 后再继续。

---

## 已完成 Phase

| Phase | 完成日期 | 备注 |
|-------|---------|------|
| **Phase 0 — 骨架与 Harness** | 2026-06-28 | 11/11 ticket 全完成；三仓库 git init + push 到 `Cavan-cloud/*`；CI 草案 + docker-compose dev + .env.example 就位 |
| **Phase 1 — 只读核心 API + 前端壳** | 2026-06-30 | 18/18 ticket 全完成；后端只读 API + 前端 6 页 + Playwright @smoke |
| **Phase 2 — 飞书同步 + 阶段映射** | 2026-07-01 | 9/9 ticket 全完成；FeishuClient + 同步 API + Worker delta/backfill + ArchUnit 只读守护 + SQL 验收脚本 |
| **Phase 3 — Gmail 同步** | 2026-07-01 | 10/10 ticket 全完成；GmailClient + 同步 API + Worker 5min + 历史引导 banner + fixture 测试 |
| **Phase 4 — Spring AI** | 2026-07-01 | 10/10 ticket 全完成；多供应商 AI + Gmail 同步分类 + 重新分析 + ai_usage_log |
| **Phase 5 — 写操作与发信** | 2026-07-03 | 20/20 ticket 全完成；写 API + 前端接线 + Gmail 冒烟 runbook |
| **Phase 6 — 定时邮件 + 生产化** | 2026-07-03 | 13/13 ticket 全完成；Worker 派发 · Docker/Helm · 可观测性 · 迁移 · 切流/回滚 · External Secrets |
| **Phase 7B — 看板 v1 Parity 补全** | 2026-07-08 | 14/14 ticket 全完成；视角 / 下钻 / 成员进度 / 平台分布 / 邮件动态 / 月份 chip / Playwright @smoke |

---

## 下一个 Phase 入口

**Phase 8 — SaaS 增强** — 待启动 ⬜

> Phase 7B 全部完成（P7B-T01～T14 ✅）。详见 [`BACKLOG.md` § Phase 8](./BACKLOG.md#phase-8--saas-增强可选46-周)。

---

## 重大决策快照

| 决策 | ADR | 状态 |
|------|-----|------|
| 后端 Java + Spring Boot | [ADR-001](./decisions/ADR-001-backend-java-spring.md) | 锁定 |
| 前端保留 Next.js | [ADR-002](./decisions/ADR-002-frontend-keep-next.md) | 锁定 |
| 数据库 PostgreSQL（不换 MySQL） | [ADR-003](./decisions/ADR-003-db-postgres.md) | 锁定 |
| AI 编排用 Spring AI | [ADR-004](./decisions/ADR-004-ai-orchestration.md) | 锁定 |
| 先建最小 Harness | [ADR-005](./decisions/ADR-005-harness-first.md) | 锁定 |
| ORM 选 MyBatis-Plus | [ADR-006](./decisions/ADR-006-orm-mybatis-plus.md) | 锁定（覆盖 ADR-003 早期建议） |
| AI 多供应商路由（Moonshot + DeepSeek，配置驱动切换） | [ADR-007](./decisions/ADR-007-ai-multi-provider.md) | 锁定 |

---

## 更新协议

每次 Agent 完成一个 ticket / 进入新 Phase / 解决阻塞，**必须**：

1. 更新"最后更新"时间戳
2. 更新"当前活跃 ticket"
3. 更新对应 Phase 完成度
4. 更新"已完成 Phase"或"下一个 Phase 入口"（如适用）
5. 在 `BACKLOG.md` 对应 ticket 行勾选 `[✅]`
6. 在 `05-feature-parity.md` 对应功能行勾选 `[✅]`（如该 ticket 关联 feature-parity）
7. 必要时新增/更新 ADR

> 更新规则的强约束写在 `.cursor/rules/00-global.mdc`。
