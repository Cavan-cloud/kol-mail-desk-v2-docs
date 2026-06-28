# kol-mail-desk-v2-docs

[![docs-ci](https://github.com/ORG/kol-mail-desk-v2-docs/actions/workflows/docs-ci.yml/badge.svg)](https://github.com/ORG/kol-mail-desk-v2-docs/actions/workflows/docs-ci.yml)

KOL Mail Desk 全量重构的共享规格仓库。所有方案、决策、阶段计划、功能对照都在这里。

> CI badge URL 中的 `ORG` 为占位符，待 P0-T11 配置 GitHub 远端后替换为真实 org/user 名。
> `docs-ci.yml` 覆盖：markdownlint（`.markdownlint.json`）· lychee 链接检查（`lychee.toml`）· Redocly OpenAPI lint（`specs/api-contract-v1.yaml`）。

## 执行轨道（每次开新窗口先读）

| 文件 | 用途 |
|------|------|
| **`specs/STATUS.md`** | **当前 Phase / 活跃 ticket / 阻塞项 — 单一事实源，每次会话必读必更** |
| `specs/BACKLOG.md` | Phase 0-7 共 99 个 ticket 的完整列表与状态 |
| `specs/SETUP.md` | 本地开发环境、外部账号清单、环境变量、首跑命令 |

## 设计参考

| 文件 | 内容 |
|------|------|
| `specs/00-refactor-plan.md` | **重构方案总览**（入口） |
| `specs/01-architecture.md` | 系统架构详细设计 |
| `specs/02-backend-design.md` | Spring Boot + Spring AI 后端设计 |
| `specs/03-frontend-reuse.md` | 前端复用评估 |
| `specs/04-phases.md` | Phase 0～7 分阶段交付计划（含每 Phase 准入与对账） |
| `specs/05-feature-parity.md` | v3.3 功能对照清单（91 条可勾选） |
| `specs/06-testing.md` | 测试策略 |
| `specs/07-risks.md` | 风险与对策 |
| `specs/api-contract-v1.yaml` | OpenAPI 契约（按 Phase 增量填充） |

## Harness 配置

| 文件 | 用途 |
|------|------|
| `harness/risk-tiers.json` | Cursor Agent 路径风险分级 |

## 决策记录（ADR）

| 文件 | 决策 |
|------|------|
| `specs/decisions/ADR-001-backend-java-spring.md` | 后端选用 Java + Spring Boot |
| `specs/decisions/ADR-002-frontend-keep-next.md` | 前端保留 Next.js |
| `specs/decisions/ADR-003-db-postgres.md` | 数据库继续 PostgreSQL（不换 MySQL） |
| `specs/decisions/ADR-004-ai-orchestration.md` | AI 编排选 Spring AI（暂不引入 FastAPI + AgentScope） |
| `specs/decisions/ADR-005-harness-first.md` | 先建最小 Harness，再进入全量重构 |
| `specs/decisions/ADR-006-orm-mybatis-plus.md` | ORM 选型确定为 MyBatis-Plus（推翻 ADR-003 早期 JPA + JdbcTemplate 建议） |

## 相关仓库

- `../kol-mail-desk-v2-backend` — Spring Boot 3 + Spring AI 后端
- `../kol-mail-desk-v2-web` — Next.js 15 + React 18 前端
- `../kol-mail-desk` — 旧仓库，**只读参考，禁止修改**

## 当前阶段

**Phase 0 — 骨架与规格固化。** 详见 `specs/STATUS.md`（实时状态）和 `specs/04-phases.md`（计划）。

## 新会话续接协议

每次新打开 Cursor 窗口、或新开 Agent 会话，**第一件事是读 `specs/STATUS.md`**。该文件由 `.cursor/rules/00-global.mdc` 强制 Agent 加载。

完成任何 ticket 必须同步更新三处：

1. `specs/STATUS.md`
2. `specs/BACKLOG.md`
3. `specs/05-feature-parity.md`（如关联 feature）

详细规则见 `.cursor/rules/00-global.mdc`。
