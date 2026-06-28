# ADR-003：数据库继续 PostgreSQL（不换 MySQL）

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** 全体后端、数据迁移

## 上下文

旧系统在 Supabase PostgreSQL 上，使用了 PG 特性较多。重构时讨论过是否改 MySQL。

## 决定

**继续使用 PostgreSQL 16。生产环境用 AWS RDS / Aurora PostgreSQL / 自建。**

## 旧系统对 PostgreSQL 的依赖

| PG 特性 | 项目用法 |
|---------|---------|
| ENUM 类型 | `kol_stage`、`kol_status`、`platform`、`email_direction`、`action_type` |
| ENUM 增量扩展 | `ALTER TYPE kol_stage ADD VALUE 'producing'` |
| Generated Column | `normalized_email = lower(trim(email))` 持久化 |
| JSONB | `ai_extracted_fields`、`actions.metadata` |
| 数组 `text[]` | `to_emails`、`cc_emails`、`attachment_names` |
| UUID + pgcrypto | 主键、`gen_random_uuid()` |
| RLS | 行级权限（应用层目前用 Service Role 绕过） |
| 复合唯一 + Upsert | `(normalized_email, feishu_operator_name)` |
| Supabase Auth | `profiles.id → auth.users(id)` |

## 换 MySQL 的成本

| 项 | 改造 |
|----|------|
| ENUM | 改 `VARCHAR + 应用枚举` |
| JSONB | MySQL `JSON`，索引/查询能力弱 |
| `text[]` | 改 `JSON` 数组或子表，应用代码全改 |
| Generated Column | MySQL 8 支持，可保留 |
| RLS | 没有，全部应用层实现 |
| Supabase Auth | 替换 Keycloak / Auth0 / 自研 |
| 迁移脚本 | 10 个 PG migration 全部重写 |

## 不换的理由

1. **数组与 JSON** 是邮件领域的天然结构（收件人、附件、AI 提取字段）
2. **PG 多租户 + RLS** 是企业 SaaS 标准模式，MySQL 全靠应用层
3. **ENUM 增量扩展** 在阶段演进中频繁使用，PG 体验远好于 MySQL
4. **应用代码** 中 `to_emails: string[]` 这类语义在 MySQL 下要全改
5. **看板复杂聚合** PG 的 CTE / 窗口函数 / 部分索引更顺手

## 何时可以改 MySQL

| 条件 | 是否触发 |
|------|---------|
| 公司硬性规定后端只能用 MySQL | 触发 |
| 已有专业 MySQL DBA 团队、不接受 PG | 触发 |
| 客户采购合规要求 | 触发 |
| 「感觉 MySQL 更通用」 | **不触发** |

## 决策依据 / 推导

详见对话讨论：「换 MySQL **能跑**，但要改 schema + 认证 + 部分应用代码；除非有明确组织/基础设施约束，否则不值得」。

## 影响

- 生产数据库：AWS RDS PostgreSQL Multi-AZ（推荐）
- 本地开发：Docker `postgres:16-alpine`
- 测试：Testcontainers `postgres:16-alpine`
- ORM：**MyBatis-Plus 3.5+ + Flyway**（详见 [ADR-006](./ADR-006-orm-mybatis-plus.md)，已推翻早期 JPA + JdbcTemplate 的初步建议）

> 注：本 ADR 早期版本曾建议 "Spring Data JPA + JdbcTemplate"，已由 ADR-006 替换。原推导思路（PG 类型完整支持）仍成立，但实现路径改为 MyBatis-Plus + 自定义 TypeHandler（`JsonbTypeHandler`、`StringArrayTypeHandler`）。
