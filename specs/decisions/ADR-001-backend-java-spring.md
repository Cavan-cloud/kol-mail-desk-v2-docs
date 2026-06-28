# ADR-001：后端选用 Java + Spring Boot

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** 全体后端

## 上下文

旧系统是 Next.js API Routes + Supabase 直连。要把它演进成 SaaS 平台，后端必须能承载：

- 长任务（Gmail 历史同步、飞书全量回填、AI 批处理）
- 异步队列与多 Worker
- 企业级身份（SAML / OIDC / SSO）
- 多租户、配额、审计、合规
- 4～10 年的长期维护

候选：

| 候选 | 优势 | 劣势 |
|------|------|------|
| **Spring Boot (Java)** | 企业生态成熟、Security/批处理/调度齐全、招聘容易 | 启动慢、内存占用高、迭代速度略慢 |
| NestJS (Node/TS) | 与现有 TS 团队语言一致 | 企业级能力（SAML、批处理）弱于 Spring |
| Go | 性能好、部署简单 | 业务代码冗长、ORM 生态弱、企业身份生态弱 |
| 继续 Next.js | 改动最少 | Serverless 60s 限制、无法承载 Worker/队列 |

## 决定

**选用 Spring Boot 3.3 + Java 21。**

理由：

1. **企业 SaaS 必备能力**：Spring Security 对 OAuth2 / SAML / OIDC 支持最完整
2. **长任务承载**：Worker 独立进程 + Spring Scheduler + 队列消费天然适配
3. **领域复杂度**：Gmail / 飞书 / AI / 邮件状态机这类业务，Java 工程化更可控
4. **未来人员补充**：Java 后端工程师在国内市场更易招聘
5. **采购评审**：企业客户对 Java 后端接受度更高

## 不选 NestJS 的理由

- SAML / 企业 SSO 生态弱
- 长任务依赖第三方库（BullMQ / Temporal SDK），稳定性不如 Spring Batch / Quartz
- 大团队多人协作下，类型与边界约束不如 Java 严格

## 不选 Go 的理由

- AI / OAuth / 邮件富文本生态比 Java 弱
- 业务代码可读性低于 Spring（DTO 校验、依赖注入、AOP）

## 不继续 Next.js 的理由

- Vercel 60s 限制无法跑历史同步、批量 AI
- 没有真正的 Worker 进程
- 多租户 / 配额 / 审计 / RLS 实施成本远高于 Spring

## 影响

- 团队需要 Java 21 + Spring Boot 培训（约 2 天）
- 部署从 Vercel 改为 K8s / ECS
- AI 编排走 Spring AI（详见 ADR-004）
- 数据库继续 PostgreSQL（详见 ADR-003）

## 备选回滚条件

如果出现以下情况，可重新评估改用 NestJS：

- 团队 Java 工程师持续招聘失败（>3 个月）
- Spring AI 在 Kimi 上反复出问题且无替代
- 业务从 SaaS 收缩回单租户内部工具
