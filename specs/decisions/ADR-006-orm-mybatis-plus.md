# ADR-006：ORM 选型确定为 MyBatis-Plus（推翻 ADR-003 中 JPA + JdbcTemplate 的初步建议）

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** 全体后端、`docs/standards/coding-standards.md`、`02-backend-design.md`
- **替代：** ADR-003 中"ORM：Spring Data JPA + JdbcTemplate"段落

## 上下文

ADR-003 决定继续使用 PostgreSQL 后，初步建议 Spring Data JPA + JdbcTemplate 双栈。原因是 Spring 官方推荐组合 + PG JSONB / Array / Generated Column 通过 `hibernate-types` 支持完整。

但是在评审阶段重新审视后发现这个初步建议存在三个偏差：

1. **没有充分尊重团队既有沉淀**：项目编码规范、工程结构原文档（来自东方财富私募产品）已建立完整的 MyBatis 规则体系，团队主力为 MyBatis 背景，强行切 JPA 等于丢弃既有沉淀。
2. **没有充分对照 maildesk 实际业务形态**：工作台多维筛选、看板漏斗（CTE + 窗口函数）、Gmail 批量 upsert、定时邮件原子认领（`UPDATE ... RETURNING`）等场景在 JPA 下大概率退化到 JdbcTemplate，最终成"JPA 名义层 + JdbcTemplate 实际层"的双范式并存。
3. **低估了 JPA 隐式行为成本**：N+1、persistence context flush、一级缓存、cascade 级联、`@EntityGraph` 等坑需要 Senior 才能稳定驾驭。

## 决定

**统一使用 MyBatis-Plus 3.5+ + Flyway，禁止混入 JPA / Hibernate。**

复杂查询场景由 MyBatis XML 内的原生 SQL 处理，**不再引入 JdbcTemplate**（除极少数 MyBatis 不便表达的场景作为逃生通道，并在代码中说明）。

## 为什么是 MyBatis-Plus 而非原生 MyBatis

MyBatis-Plus 把 JPA 提供的横切关注点全部封装为开箱组件，几乎补齐了 JPA 的便利性：

| 横切关注点 | JPA 自带 | MyBatis-Plus 提供 |
|-----------|---------|------------------|
| 多租户 `tenant_id` 自动注入 | `@TenantId` | `TenantLineInnerInterceptor` |
| 审计字段自动填充（`created_at` / `updated_at` / `created_by` / `updated_by`） | `@CreatedDate` + `AuditingEntityListener` | `MetaObjectHandler` |
| 乐观锁 | `@Version` | `OptimisticLockerInnerInterceptor` |
| 软删除 | `@SQLDelete` + `@Where` | `@TableLogic` |
| 分页 | `Pageable` | `PaginationInnerInterceptor` |
| 基础 CRUD | `JpaRepository` | `BaseMapper<T>` |
| 条件构造 | Criteria / Specification | `QueryWrapper` / `LambdaQueryWrapper` |
| SQL 监控 | Actuator metrics | 集成 p6spy |

差距只剩"实体生命周期事件"（`@PostUpdate` 等）和"JSONB / Array 类型映射"，前者用 AOP 替代，后者写两个 TypeHandler 放 `maildesk-common`（一次性约 60 行）。

## 为什么不再保留 JdbcTemplate 兜底

MyBatis XML 内**可以写任意复杂的原生 SQL**，包括 CTE、窗口函数、`RETURNING`、`ON CONFLICT`、CASE WHEN、`generate_series`、`UNNEST` 等 PG 特性。JdbcTemplate 能写的，XML 都能写，并且：

- 共享 MyBatis 的参数绑定、结果集映射、TypeHandler、Plugin 链路
- 不需要重复配置数据源
- 不会出现"两套范式认知负担"

仅当遇到**MyBatis XML 严重不便**的场景（例如需要按动态结果集字段做反射映射、或与 Spring `JdbcOperations` 接口对接的第三方库）才退到 JdbcTemplate，需在代码注释说明原因。

## 选型对比

| 维度 | JPA + JdbcTemplate | **MyBatis-Plus（选定）** | 原生 MyBatis |
|------|-------------------|------------------------|-------------|
| 团队学习成本 | 高 | **极低**（沿用原项目沉淀） | 低 |
| SQL 可控性 | 中（Hibernate 生成） | **高**（人工写） | 高 |
| 复杂查询表达力 | 退回 JdbcTemplate | **优秀**（XML 原生 SQL） | 优秀 |
| 批量 upsert | `saveAll` 退化 / 写 JdbcTemplate | **优秀**（`<foreach>` + `ON CONFLICT`） | 优秀 |
| 多租户自动注入 | `@TenantId` | **Interceptor 开箱** | 需自写 Plugin |
| 审计字段自动填充 | `AuditingEntityListener` | **MetaObjectHandler 开箱** | 需自写 |
| 软删除 | `@SQLDelete` | **`@TableLogic` 开箱** | 需自写 |
| 乐观锁 | `@Version` | **Interceptor 开箱** | 需自写 |
| 分页 | `Pageable` | **Interceptor 开箱** | 需自写 |
| PG JSONB 映射 | hibernate-types | 自定义 TypeHandler（约 30 行） | 自定义 TypeHandler |
| PG Array 映射 | hibernate-types | 自定义 TypeHandler（约 30 行） | 自定义 TypeHandler |
| DDD 实体表达 | 强 | 中 | 中 |
| Repository → DAO 风格 | Domain 风格 | 偏 DAO | 偏 DAO |
| N+1 风险 | 高（默认懒加载） | **无**（手写 SQL） | 无 |
| persistence context 坑 | 有 | **无** | 无 |
| SQL 日志可读性 | 差 | **直接可读** | 直接可读 |
| 国内 DBA 友好度 | 中 | **高** | 高 |

## 影响

### 模块结构调整

- `maildesk-domain` 中 `Repository` 接口 → **`Mapper` 接口**（继承 `BaseMapper<T>`）
- `maildesk-infrastructure` 不再有 Repository 实现类（MyBatis-Plus 运行时生成）
- 新增 `maildesk-infrastructure/src/main/resources/mapper/*.xml` 用于复杂 SQL
- `maildesk-common` 新增 `TypeHandler/`：`JsonbTypeHandler`、`StringArrayTypeHandler`
- `maildesk-infrastructure/.../config/MyBatisPlusConfig.java` 注册 Interceptor、MetaObjectHandler、TypeHandler

### 实体表达约定

- 实体使用 MyBatis-Plus 的 `@TableName` / `@TableId` / `@TableField` / `@TableLogic` 注解
- 不使用 JPA 的 `@Entity` / `@Table` / `@Column`
- 实体保持贫血模型；领域规则放在 `maildesk-domain/.../service/` 的 Domain Service 中

### 横切关注点强制要求

- 所有业务表必须开启 `TenantLineInnerInterceptor` 自动注入 `tenant_id`，Mapper 查询不需要手写 `tenant_id = ?`
- 所有业务表必须有 `created_at` / `updated_at` / `created_by` / `updated_by`，由 `MetaObjectHandler` 自动填充
- 软删除字段统一为 `deleted_at TIMESTAMPTZ`，标注 `@TableLogic(value = "null", delval = "now()")`
- 乐观锁字段名为 `version INTEGER`

### 审计 log（`actions` 表）

- 不通过 MyBatis-Plus 的 `MetaObjectHandler` 写（其作用域是 created/updated 等字段）
- 通过自定义注解 `@AuditAction` + AOP 切面统一写入

### Flyway 不变

数据库迁移仍由 Flyway 管理；MyBatis-Plus 启动时不生成 DDL（无对应能力，安全）。

### 依赖

```xml
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
    <version>3.5.7</version>
</dependency>
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-jsqlparser</artifactId>
    <version>3.5.7</version>
</dependency>
```

不引入：

- `spring-boot-starter-data-jpa`
- `hibernate-core`
- `hibernate-types-*`

## 验证标准

- ArchUnit 测试：禁止 `import jakarta.persistence.*` 与 `import org.hibernate.*`
- CI 启动测试：MyBatis-Plus 多租户拦截器生效（写入路径自动带 `tenant_id`，查询路径自动追加 `WHERE tenant_id = ?`）
- 集成测试：Testcontainers + Flyway + MyBatis-Plus 全链路启动通过

## 何时可以反悔回 JPA

| 条件 | 触发 |
|------|------|
| 团队核心人员全部更换为 JPA 背景 | 触发，但需经一次 ADR 评审 |
| 业务从 SQL 重型转为简单 CRUD（管理后台为主） | 不触发（已既定） |
| MyBatis-Plus 长期停更或重大兼容性问题 | 触发 |
| 「JPA 更现代」/「Spring 推荐 JPA」 | **不触发** |

## 决策依据 / 推导

详见对话讨论与 `01-architecture.md` 中数据访问层设计。核心权衡是：**maildesk 大量动态查询 + 聚合 + 批量场景 + 既有 MyBatis 团队沉淀 → MyBatis-Plus 整体收益高于 JPA**。
