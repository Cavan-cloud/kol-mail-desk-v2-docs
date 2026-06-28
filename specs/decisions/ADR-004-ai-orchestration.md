# ADR-004：AI 编排选用 Spring AI（暂不引入 FastAPI + AgentScope）

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** AI 模块、未来 Agent 能力扩展

## 上下文

业务里已有 4 个 AI 能力（分类、翻译、草稿、自检），形态统一：

```
输入校验 → System Prompt → 单次 LLM 调用 → JSON 解析 → 校验 → 失败 fallback
```

讨论过两种实现：

| 方案 | 描述 |
|------|------|
| A | FastAPI + AgentScope 独立 AI 服务 |
| B | Spring AI 集成到主后端 |

## 决定

**首版使用方案 B：Spring AI 集成。**

**未来在以下条件下重新评估方案 A：**

- AI 能力扩展到多步 Agent（草稿 Agent → 检查 Agent → 修订 Agent）
- 需要 Tool Calling（查 KOL 历史 / 模板 / 飞书字段）
- 需要 RAG / 长程记忆
- 团队补充了 Python / 算法工程师

## 当前业务的 AI 复杂度

| 能力 | 实现 | 复杂度 |
|------|------|--------|
| `classifyEmail` | 单次 chat + JSON | 低 |
| `translateText` | 单次 chat | 低 |
| `generateReplyDraft` | 单次 chat + 多上下文 | 中 |
| `checkDraft` | 单次 chat + JSON | 低 |
| 降级 fallback | 正则 heuristic | 低 |

**没有：**

- 多 Agent 协作
- Tool Calling 循环
- ReAct / Plan-Execute
- 长程记忆
- 自主决策

业务规则也写死在 Prompt 里（AI 不决定阶段、永不自动发信），不需要 Agent 框架。

## 选 Spring AI 的理由

1. **单后端栈**：鉴权、租户、审计、配额统一
2. **当前能力够用**：Spring AI `ChatClient` + 结构化输出 + 重试 + 观测齐全
3. **运维一份**：不引入第二门语言、第二套部署
4. **企业客户视角**：Java 后端统一更易接受

## 不选 FastAPI + AgentScope 的理由（首版）

- AgentScope 是为多 Agent 设计的，给单次调用用是 overkill
- 多一门语言、一套部署、一套监控
- 鉴权 / 配额 / 审计要在 AI 服务里重做或通过 Gateway 注入
- 当前 Prompt 实验需求小，没有快速迭代的瓶颈

## 演进路径（Phase 7+ 可考虑）

```
现在 v1：Spring AI + 4 个 Pipeline
   ↓
中期 v2：仍 Spring AI，但拆出 AI Orchestrator 独立 Spring 服务
   ↓
未来 v3：当 Agent 需求出现时，再加 FastAPI sidecar（Python + AgentScope）
        Spring 通过 gRPC/HTTP 调 sidecar
```

## 实施约束（Spring AI）

- `spring-ai-openai-spring-boot-starter`
- `spring.ai.openai.base-url = https://api.moonshot.cn/v1`
- Prompt 在 `resources/prompts/*.st`
- 结构化输出：`response-format: json_object` + Bean Validation
- 模型分流：8k / 128k 按场景
- 失败 fallback：必须保留邮件入库
- 用量日志：`ai_usage_log` 记录 tokens / 耗时 / 成本

## 影响

- AI 编排责任在 `maildesk-ai` 模块
- Prompt 从 `lib/ai/prompts.ts` 迁入 `prompts/*.st`，1:1 对应
- 未来切 OpenAI / Claude：只改 `base-url` 与 `api-key`，业务代码不变
- 未来加 Agent：在 `maildesk-ai` 引入 Spring AI Function Calling，仍单后端
