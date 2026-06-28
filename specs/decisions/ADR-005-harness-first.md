# ADR-005：先建最小 Harness，再进入全量重构

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** Phase 0、整个重构过程的 Agent 协作方式

## 上下文

重构周期 4～5 个月。期间会大量使用 AI Agent（Cursor）协助开发。Agent 需要明确的：

- 项目契约（栈、模块边界、Phase）
- 路径风险分级
- 规则与禁止事项
- API 契约（OpenAPI）

如果不提前建立这套「Harness」，Agent 容易：

- 偏离 Spring / Next 边界（在错误模块里写代码）
- 重复犯同一类错（如绕过 API 契约）
- 各 Phase 标准不一致
- 误改旧仓库

## 决定

**Phase 0 必须先建最小 Harness（2～3 天），之后再开始任何业务代码。**

「最小 Harness」包括：

```
kol-mail-desk-v2-docs/
├── AGENTS.md（后端 + 前端各一份）
├── .cursor/rules/{00-global, backend-java, frontend-next}.mdc
├── specs/{00-refactor-plan, 01-architecture, ..., 07-risks}.md
├── specs/decisions/ADR-001..005.md
├── specs/api-contract-v1.yaml（占位，按 Phase 填）
└── harness/risk-tiers.json
```

## 不选「先全量 Harness」的理由

完整 harness 模板（`src/rules` + harness-compiler + Hooks）一次性搭出来：

- 4～7 天工期，Phase 1 推迟
- 规则、模板会在 Phase 1～3 中反复修改
- Compiler / Hooks 投入大但 Phase 0 用不上

→ **采用「按 Phase 增量补 Harness」**：每个 Phase 结束后，把踩过的坑写成规则。

## 不选「先全量重构」的理由

裸奔 4～5 个月使用 Agent：

- Agent 在错误模块加代码（无 ArchUnit 守边界）
- Spec 与代码漂移，Phase 5 时无法回溯决策
- 多人多 Phase 协作标准不统一
- 旧仓库被误改的风险

## 增量 Harness 策略

| Phase 完成后增补 | 内容 |
|------------------|------|
| Phase 1 | `workbench-api.mdc`、OpenAPI lint CI |
| Phase 2 | `feishu-mapping.mdc` 阶段映射检查 skill |
| Phase 3 | `gmail-sync.mdc` 关键不变量 + ArchUnit |
| Phase 4 | `ai-prompts.mdc`、token 用量监控 |
| Phase 5 | `audit-log.mdc` 所有写操作必须 audit |
| Phase 6 | E2E checklist 自动化 |

**原则：**

- 同样的错犯两次 → 写进 rule
- 能写成测试 → 优先测试（CI 比规则更可靠）
- Spec 与代码不一致 → 立刻同步

## Harness.io Cursor Plugin 集成

> 注：Harness.io 是 CI/CD 平台，不同于「harness engineering」概念。

首版 **不接** Harness.io Plugin。理由：

- CI/CD 用 GitHub Actions 已足够
- Plugin 适合已有 Harness.io 客户，本项目暂无
- 不阻塞重构，Phase 7 可评估

## 影响

- Phase 0 多花 2～3 天，但后续 Phase 风险降低
- 团队成员（人 + Agent）都遵循同一份 AGENTS.md
- 决策可追溯（ADR + Phase 验收）
- 任何新 Agent 任务首先读 `specs/00-refactor-plan.md`

## 当前状态

- [x] 三个仓库目录建立
- [x] AGENTS.md（后端 / 前端）
- [x] `.cursor/rules` 文件已写入（暂存为 `cursor-rules-staging/`，待用户重命名）
- [x] 7 份 specs + 5 份 ADR
- [x] `harness/risk-tiers.json`
- [ ] OpenAPI Phase 1 端点（Phase 1 时补）
- [ ] CI 模板（Phase 0 末期）
