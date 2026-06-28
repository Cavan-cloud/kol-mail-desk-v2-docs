# Lovart Mail Desk 全量重构方案

> 入口文档。各章节有独立详细规格，本文档作为概览与导航。

## 一、重构目标

| 目标 | 说明 |
|------|------|
| 功能零丢失 | 覆盖 v3.3 使用说明书全部能力（工作台、看板、团队、模板、定时、Gmail/飞书/AI） |
| 后端统一 | Spring Boot 3 + Spring AI，替代 Next.js API + Supabase 直连 |
| 前端复用 | 保留 React/Next.js UI 与交互，替换数据层与认证 |
| SaaS 就绪 | 首版交付单租户（Lovart），数据模型预留 `tenant_id` |
| 可运维 | Worker 独立部署，Gmail/飞书/定时任务脱离 Serverless 60s 限制 |

## 二、不在首版范围（与 v3.3 PRD 一致）

- 飞书双向同步（保持只读）
- 移动端
- 实时协同
- AI 自动发信（必须人工确认）
- 自定义阶段配置

## 三、技术选型

| 层 | 选型 | 决策依据 |
|----|------|----------|
| 前端 | Next.js 15 + React 18 + TypeScript + Tailwind | ADR-002 |
| 后端 | Spring Boot 3.3 + Java 21 | ADR-001 |
| AI 编排 | Spring AI（OpenAI 兼容，连接 Kimi/Moonshot） | ADR-004 |
| 数据库 | PostgreSQL 16 + Flyway | ADR-003 |
| 缓存 / 锁 | Redis | — |
| 队列 | Redis Streams（首版）→ Kafka（规模化） | — |
| 调度 | Spring Scheduler + Redis 分布式锁 | — |
| 认证 | Spring Security 6 + OAuth2 | — |
| 部署 | 前端 Vercel / 静态；后端 K8s 或 ECS；Worker 独立 Deployment | — |

## 四、功能 → 服务映射

按 v3.3 使用说明书章节对照：

| v3.3 章节 | 功能点 | 后端模块 | 前端复用度 |
|-----------|--------|----------|-----------|
| 登录流程 | Google OAuth、Gmail scope、测试用户 | auth-service | 重写登录/回调 |
| §1 产品概览 | 达人中心、飞书+Gmail 聚合 | core + integration | 高 |
| §2 新人上手 | 资料、飞书运营名、Gmail 同步 | team + gmail-sync | 高 |
| §3 工作台 | 导航、统计、搜索、列表、详情 | workbench-api | **高（核心 UI）** |
| §3.5 邮件阅读 | HTML 渲染、历史折叠 | 纯前端 | **完全复用** |
| §3.6 处理状态 | 无需回复、已读/未读 | kol-api + email-api | 高 |
| §4 撰写回复 | 富文本、CC、AI 草稿、发送 | gmail-send + ai-service | **高（DraftSendPanel）** |
| §5 团队看板 | KPI、时间窗、漏斗、转化率 | board-api | 中（JSX 复用，数据改 API） |
| §6 阶段映射 | 飞书状态 → 10 阶段 | feishu-sync + domain | `domain.ts` 复用 |
| §7 团队成员 | 角色、mentor、离职、分配 | team-api | 高 |
| §8 模板 | 私有模板 CRUD | template-api | **完全复用** |
| §9 定时邮件 | 排程、取消、Cron 发送 | scheduler-service | 高 |
| §10 FAQ | 飞书日期、陌生人过滤、AI 降级 | 业务规则层 | N/A |

详见 `05-feature-parity.md` 的完整验收清单。

## 五、目标架构（详见 01-architecture.md）

核心原则：

1. 前端继续 React/Next.js，不改为 SPA
2. 后端拆「同步 API + 领域服务 + Worker」三层
3. PostgreSQL 仍是主库，多租户用 `tenant_id` + RLS
4. 集成层独立，Gmail / 飞书 / 未来 CRM 可插拔
5. AI 单独编排，便于换模型、控成本、做租户配额

## 六、前端复用评估（详见 03-frontend-reuse.md）

**结论：UI 约 70～75% 可复用；整体代码约 40～45% 原样保留。**

| 类别 | 文件 / 规模 | 复用度 |
|------|------------|--------|
| 纯 UI 组件 | `components/*` ~3,584 行 | 85～90% |
| 领域常量 | `lib/domain.ts` 等 | 100% |
| AI Prompt | `lib/ai/prompts.ts` | 100% |
| SSR 页面 | `app/*/page.tsx` ~1,700 行 | 50～60% |
| 认证相关 | session-bridge、google-sign-in 等 | 0～10%（重写） |
| 数据层 | `lib/data/*`、`lib/gmail/*`、`lib/feishu/*` | 0%（删除，后端承担） |

## 七、后端设计摘要（详见 02-backend-design.md）

Maven 模块结构：

```
maildesk-common         # DTO、枚举、异常
maildesk-domain         # 实体、Repository 接口、领域规则
maildesk-infrastructure # MyBatis-Plus 配置 + Mapper XML、Redis、OAuth Token 存储
maildesk-integration    # gmail/、feishu/
maildesk-ai             # Spring AI：classify/draft/check/translate
maildesk-application    # 用例服务
maildesk-api            # REST Controller + Security
maildesk-worker         # 定时任务、队列消费（独立启动类）
```

**首版建议模块化单体（Modular Monolith）**，不要一开始拆 8 个微服务；按 Maven module 划分边界，Worker 可独立启动。

## 八、分阶段计划（详见 04-phases.md）

| Phase | 内容 | 周期 |
|-------|------|------|
| 0 | 骨架 + Harness（当前） | 2～3 周 |
| 1 | 只读核心 API + 前端壳 | 3～4 周 |
| 2 | 飞书同步 | 2～3 周 |
| 3 | Gmail 同步 | 3～4 周 |
| 4 | Spring AI | 2 周 |
| 5 | 写操作与发信 | 3 周 |
| 6 | 定时邮件 + 生产化 | 2 周 |
| 7（可选） | SaaS 增强（多租户、Gmail Push、OpenSearch） | 4～6 周 |

**总工期：17～22 周（4～5.5 个月）达到 v3.3 功能对齐。**

## 九、团队建议

| 角色 | 人数 | 职责 |
|------|------|------|
| 后端 Java | 2 | Spring Boot、Gmail/飞书、Worker |
| 前端 | 1 | Next 改造、api-client、联调 |
| 全栈 / TL | 1 | 架构、OpenAPI、迁移、Review |
| QA | 0.5 | v3.3 场景回归清单 |

## 十、风险摘要（详见 07-risks.md）

| 风险 | 对策 |
|------|------|
| Gmail 同步语义回归 | 移植 `persist.ts` 时写对照测试；双跑 diff |
| OAuth token 迁移 | 必要时用户重新授权 |
| 看板聚合性能 | SQL COUNT + Redis 缓存 |
| Spring AI JSON 不稳定 | 结构化输出 + Zod 等价校验 + 重试 + fallback |
| 工期膨胀 | 严格 Phase 交付，Phase 1 结束即可内部预览 |

## 十一、最终建议

1. **后端**：Spring Boot 模块化单体 + 独立 Worker + Spring AI
2. **数据库**：继续 PostgreSQL，不换 MySQL
3. **前端**：保留 Next.js + 30 个组件，重写 auth + data layer
4. **复用比例**：UI/交互 ~70%+，整体代码 ~40～45% 原样保留
5. **最大重写**：`lib/gmail/*`、`lib/feishu/*`、`lib/data/*`、全部 Next API Routes
6. **首版是否 SaaS**：单租户交付，schema 预留 `tenant_id`
7. **顺序**：先最小 Harness（已完成）→ Phase 0 骨架 → Phase 1～6

## 十二、当前进度

- [x] 最小 Harness（AGENTS.md、.cursor/rules、docs/specs 骨架）
- [x] 三个独立仓库目录已建立
- [ ] 完整重构方案规格写入 docs/specs/（本批次任务）
- [ ] 进入 Phase 1：Spring 初始化 + Next 初始化
- [ ] 补全 `api-contract-v1.yaml` Phase 1 端点

## 十三、相关 ADR

- ADR-001：后端选用 Java + Spring Boot（而非 NestJS、Go）
- ADR-002：前端保留 Next.js（而非改 Vite SPA）
- ADR-003：数据库选用 PostgreSQL（不换 MySQL）
- ADR-004：AI 编排选用 Spring AI（暂不引入 FastAPI + AgentScope）
- ADR-005：Harness 先于全量重构
