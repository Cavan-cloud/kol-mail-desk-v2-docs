# 项目当前状态（Single Source of Truth）

> **每次新会话开头必读，每次完成 ticket 必更新。**
> 该文件是 Agent 跨会话续接的唯一依据。任何与本文件冲突的"猜测"都应作废。

---

## 元信息

| 字段 | 值 |
|------|-----|
| 最后更新 | 2026-07-01（Phase 2 完成） |
| 更新者 | Agent — Phase 2 飞书同步（P2-T01~T09） |
| Git 提交 | 三仓库首次 commit 已完成并推送到 `github.com/Cavan-cloud/kol-mail-desk-v2-{backend,web,docs}` main 分支 |
| 项目相对天数 | D0（计划期） |
| 工作模式 | **multi-root workspace**：`~/code/maildesk-v2.code-workspace`（已创建） |

---

## 当前 Phase

**Phase 2 — 飞书同步 + 阶段映射（9/9）✅**

Phase 0、Phase 1 已完成。详见 [`04-phases.md` § Phase 2](./04-phases.md#phase-2--飞书同步) · [`BACKLOG.md` § P2](./BACKLOG.md#phase-2--飞书同步2-3-周)。

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

**无 — 等待人工挑选**

> ✅ **Phase 2 全部完成**（2026-07-01）：P2-T08 `FeishuBackfillRunner`（`spring.profiles.active=backfill`）+ P2-T09 `scripts/feishu-stage-mapping-audit.sql`。
>
> **推荐下一 Phase**：Phase 3 — Gmail 同步（从 P3-T01 或 P3-T02 起）。

---

## 阻塞项

| 阻塞 | 影响 ticket | 等待 |
|------|-----------|------|
| 无 | — | — |

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

---

## 下一个 Phase 入口

**Phase 3 — Gmail 同步** — 推荐 **P3-T01**（`GmailClient`）或 **P3-T02**（`integration_credentials` 加密存取）。

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
