# 项目当前状态（Single Source of Truth）

> **每次新会话开头必读，每次完成 ticket 必更新。**
> 该文件是 Agent 跨会话续接的唯一依据。任何与本文件冲突的"猜测"都应作废。

---

## 元信息

| 字段 | 值 |
|------|-----|
| 最后更新 | 2026-06-28 13:25 (UTC+8) |
| 更新者 | Agent (Claude) — 完成 P0-T11（三仓库 git init + 首次 commit + push 到 Cavan-cloud），Phase 0 全部完成 |
| Git 提交 | 三仓库首次 commit 已完成并推送到 `github.com/Cavan-cloud/kol-mail-desk-v2-{backend,web,docs}` main 分支 |
| 项目相对天数 | D0（计划期） |
| 工作模式 | **multi-root workspace**：`~/code/maildesk-v2.code-workspace`（已创建） |

---

## 当前 Phase

**Phase 0 — 骨架与 Harness（✅ 已完成，等待进入 Phase 1）**

详见 [`04-phases.md` § Phase 0](./04-phases.md#phase-0--骨架与-harness)。

### Phase 0 完成度

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

**无 — Phase 0 全部完成，等待人工挑选 Phase 1 起始 ticket**

Phase 1 推荐起点（按依赖顺序）：

- **P1-T01** Maven 父 POM + 8 子模块骨架 + ArchUnit 守护 — 无前置依赖，~1.5 人日（**强烈推荐先做，给后续所有后端 ticket 立柱子**）
- **P1-T11** OpenAPI 契约填充 Phase 1 全部端点 — 无前置依赖，~1 人日（可与 P1-T01 并行做，先把契约钉住）
- **P1-T12** Next.js 项目初始化 + Tailwind / globals.css 迁入 — 无前置依赖，~1 人日（前端起手）

进入 Phase 1 前还应：

1. 重新读一遍 `04-phases.md § Phase 1 进入准入`，确认 8 项准入全部 ✅
2. 在 Cavan-cloud 三个 GitHub repo 开启 branch protection（main 分支禁止 force push，PR 必须过 CI）

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

---

## 下一个 Phase 入口

完成 P0 全部 ticket 后进入 **Phase 1 — 只读核心 API + 前端壳**。
入口检查清单详见 `04-phases.md` § Phase 1 「进入准入」与 `BACKLOG.md` § P1。

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
