# ADR-007：AI 多供应商路由（Moonshot + DeepSeek，配置驱动切换）

- **状态：** Accepted
- **日期：** 2026-07-01
- **影响范围：** `maildesk-ai` 模块、`application.yml` 配置、`SETUP.md` 环境变量、`ai_usage_log`

## 上下文

ADR-004 已选定 Spring AI + OpenAI 兼容协议对接 Kimi/Moonshot，并预留了"未来切 OpenAI / Claude 只改 base-url 与 api-key"的可能性，但当时只落地了单一供应商。

在 Phase 4 落地前重新评估，有三点新诉求：

1. **单点风险**：只接 Moonshot 一家，遇到涨价 / 限流 / 服务中断时业务无退路。
2. **成本诉求**：按 2026-07 实时报价，DeepSeek `deepseek-v4-flash` 输出单价 ¥2/百万 token，远低于 `moonshot-v1-8k` 的 ¥12/百万 token（输入输出同价），对分类、翻译这类调用量较大的能力有明显优化空间（详见 `02-backend-design.md` §2.8）。
3. **运维诉求**：切换或新增供应商应该是"改配置文件 + 填 API Key"，不需要改代码、不需要重新编译发版。

技术前提：DeepSeek API 与 Moonshot 一样是 OpenAI 兼容协议（`base_url` + `api_key` + `model` 三元组，支持 `response_format: json_object`），Spring AI 的 `spring-ai-openai-spring-boot-starter` 可以复用同一套客户端类对接两家，**不需要引入新的 starter 依赖**。

## 决定

在 `maildesk-ai` 模块内实现一层轻量供应商路由，替代 Spring Boot 对 `spring.ai.openai.*` 的单例自动配置：

1. **`AiProviderProperties`**（`@ConfigurationProperties(prefix = "maildesk.ai")`）描述 N 个 provider（当前：`moonshot`、`deepseek`）+ 每个 provider 下每个能力（classify/draft/check/translate）对应的模型 ID。
2. **每个 provider 手动注册一个 `OpenAiApi` + `OpenAiChatModel` Bean**（按名字 `@Qualifier`），不复用 Spring Boot 对 `spring.ai.openai.*` 的单一自动配置 Bean（那种方式只能配一家）。
3. **`AiModelRouter`** 按"能力"解析出应该用哪个 provider 的 `ChatModel`：
   - 优先取 `maildesk.ai.capabilities.<name>.provider`
   - 未配置则回退到 `maildesk.ai.default-provider`
   - 调用失败（401 / 429 / 超时 / 余额不足）→ 若配置了 `fallback-provider`，自动重试一次该能力对应的 fallback 供应商 → 仍失败才走 ADR-004 已定义的 heuristic 兜底（三级链路：主供应商 → 备用供应商 → 本地规则）
4. 所有 API Key 走环境变量注入（`MOONSHOT_API_KEY` / `DEEPSEEK_API_KEY`），不写死在 yml、不进代码库。

**切换供应商 = 改 `AI_DEFAULT_PROVIDER` 环境变量（或某个能力的 `provider` 配置项）+ 确保对应 `*_API_KEY` 已填，重启生效，不用碰代码。**

## 配置结构（`application.yml`）

```yaml
maildesk:
  ai:
    default-provider: moonshot   # moonshot | deepseek，全局默认
    providers:
      moonshot:
        base-url: https://api.moonshot.cn/v1
        api-key: ${MOONSHOT_API_KEY:}
      deepseek:
        base-url: https://api.deepseek.com
        api-key: ${DEEPSEEK_API_KEY:}
    capabilities:
      classify:
        provider: moonshot
        model: moonshot-v1-8k
        fallback-provider: deepseek
        fallback-model: deepseek-v4-flash
      draft:
        provider: moonshot
        model: moonshot-v1-128k
      check:
        provider: moonshot
        model: moonshot-v1-8k
      translate:
        provider: moonshot
        model: moonshot-v1-8k
        fallback-provider: deepseek
        fallback-model: deepseek-v4-flash
```

## 现状能力 × 模型映射（首版默认值）

| 能力 | 默认 provider | 模型 | 说明 |
|------|--------------|------|------|
| `classify` | moonshot | `moonshot-v1-8k` | 可切 `deepseek-v4-flash`（更便宜，需先做人工抽样质量对比再切默认值） |
| `draft` | moonshot | `moonshot-v1-128k` | 长上下文；DeepSeek 侧对应 `deepseek-v4-pro`（同为百万级上下文） |
| `check` | moonshot | `moonshot-v1-8k` | 同 classify |
| `translate` | moonshot | `moonshot-v1-8k` | 同 classify；成本结论见 `02-backend-design.md` §2.8 |

> ⚠️ **DeepSeek 模型 ID 时效提示**：`deepseek-chat` / `deepseek-reasoner` 别名将于 **2026-07-24 15:59 UTC 停用**，接入时直接用新模型 ID `deepseek-v4-flash` / `deepseek-v4-pro`，避免刚上线就要迁移。
>
> ⚠️ **思考模式提示**：DeepSeek V4 支持"思考模式"，可能默认开启，思考过程会计入输出 token、拉高成本和延迟。`classify`/`check`/`translate` 这类低延迟确定性任务在 P4-T01 落地时必须显式验证并关闭思考模式；`draft` 是否受益于思考模式可以留待质量评估后再定。

## 不做的事情（本次范围之外）

- 不做"多供应商投票/多数决"（同一次调用打给两家取共识），复杂度与当前收益不匹配。
- 不做按请求动态灰度路由（如 10% 流量走 DeepSeek），首版只支持"按能力静态配置 + 主备 fallback"；动态灰度留到有真实 `ai_usage_log` 数据后再评估。
- 不引入 Moonshot / DeepSeek 之外的其他供应商；如需新增，走同样的 provider 注册模式，成本很低，但本次不预先实现。
- 不做每租户自带 Key（`integration_credentials.type='kimi'` 预留字段是面向未来 SaaS 多租户场景，与本次全局 env var 配置机制是两回事，暂不合并）。

## 影响

- `maildesk-ai` 新增 `AiProviderProperties` / `AiModelRouter` / 两组 `OpenAiChatModel` Bean。
- `application.yml`（api + worker）新增 `maildesk.ai.*` 配置块。
- `.env` / `.env.example` / `SETUP.md`：`KIMI_*` 改名为 `MOONSHOT_*`（对齐 provider 命名），新增 `AI_DEFAULT_PROVIDER` / `DEEPSEEK_API_KEY` / `DEEPSEEK_BASE_URL`。
- `ai_usage_log`（P4-T10）新增 `provider` 列，便于按供应商拆分成本 / 成功率 / 延迟数据。
- `BACKLOG.md` P4-T01 范围从"接入 Kimi"扩大为"接入 Moonshot + DeepSeek 双供应商 + provider 路由/fallback"，预估从 0.5d 调整为 1.5d。
