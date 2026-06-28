# 后端设计（Spring Boot + Spring AI）

## 一、Maven 模块详细职责

| 模块 | 职责 | 依赖 |
|------|------|------|
| `maildesk-common` | DTO、枚举、异常基类、工具方法 | （无业务依赖） |
| `maildesk-domain` | 领域实体、Mapper 接口、领域服务接口、领域规则 | common |
| `maildesk-infrastructure` | MyBatis-Plus 配置、Mapper XML、Redis、对象存储、加密、Token 持久化 | domain |
| `maildesk-integration/gmail` | Gmail API 调用、邮件解析、发信 | domain |
| `maildesk-integration/feishu` | 飞书 OAuth、Sheet 读取、字段映射 | domain |
| `maildesk-ai` | Spring AI ChatClient、Prompt 模板、降级 fallback | domain |
| `maildesk-application` | 用例编排（多领域协作） | domain + integration + ai |
| `maildesk-api` | REST Controller、Spring Security、OpenAPI（启动类） | application |
| `maildesk-worker` | 定时任务、队列消费（独立启动类） | application |

## 二、领域服务详细设计

### 2.1 WorkbenchService（对应 v3.3 §3）

输入：

- `view`：`mine` / `pool` / `all`
- `stageFilter`：阶段枚举或 `all`
- `q`：搜索关键词
- `pagination`

输出：KOL 列表 + 侧栏统计

关键规则（从旧仓库 `lib/workbench.ts` 迁移）：

```java
// 需我回复
needsReply = direction == INBOUND && reply_resolved == false

// 仅飞书登记邮箱入库（Gmail 同步守卫）
isFeishuBacked = source == "feishu" || feishu_record_id != null

// 已读
is_read 只在 INSERT 时从 Gmail UNREAD 标签写入
UPDATE 路径不修改 is_read
```

性能要点：

- 「全部」视图避免 `LIMIT 1000` 截断 → 用 `COUNT(*)` 单独取总数
- 利用 `idx_emails_user_sent (user_id, sent_at DESC)` 覆盖索引

### 2.2 BoardService（对应 v3.3 §5）

时间窗：

| 选项 | 实现 |
|------|------|
| 全部时间 | 无过滤 |
| 本周 | `feishu_outreach_at >= date_trunc('week', now())` |
| 本月 | `feishu_outreach_at >= date_trunc('month', now())` |
| 最近 30 天 | `feishu_outreach_at >= now() - interval '30 days'` |
| 指定月份 yyyy-MM | `feishu_outreach_at` 在该月范围 |

两种模式：

- **累计漏斗**：每个阶段统计「本阶段及以后」累计人数
- **阶段分布**：每个阶段只统计当前正处于该阶段的人数

聚合 SQL 单次返回，应用层不做循环；结果缓存 Redis 60s（仿照旧 `BOARD_AGG_TAG`）。

### 2.3 FeishuSyncService（对应 v3.3 §6、§7）

只读同步飞书 Sheet → Supabase `kols` 表。

字段映射（从飞书表头解析）：

| 飞书列 | 后端字段 |
|--------|----------|
| `KOL用户名` | `name` |
| `联系方式` | `email` |
| `账号（主页链接）` | `external_profile_url` |
| `主页链接合集` | （次要 URL） |
| `主平台` | `primary_platform` |
| `频道类型` | `type` |
| `运营` | `feishu_operator_name` |
| `报价` / `最终合作价格` / `品牌报价` / `KOL报价($)` | `agreed_price`（按优先级） |
| `状态` | 经 `mapFeishuStage()` 映射到 `kol_stage` |
| `建联时间` 等 | `feishu_outreach_at`（多源解析） |

阶段映射表（v3.3 §6 完整对照）：

| 飞书状态 | 工作台阶段 |
|----------|------------|
| 已询价 / 询价 / 追+ / 二追 / 追加 / 其他追问 | `outreach`（触达） |
| 议价中 / 议价 | `negotiating`（沟通/议价） |
| 价格确定待合作 / 已合作待签合同 / 已合作 | `confirmed`（确认合作） |
| 待脚本 / 脚本修改中 / 待初稿 / 修改视频中 | `producing`（制作中） |
| 已审核待发布 / 待发布 | `reviewing`（审稿/待发布） |
| 已发布待付款 | `published`（发布） |
| 已付款 | `paying`（付款） |
| 合作过 | `reinvest`（复投） |
| 已拒绝 / 剔除合作 / 放弃合作 | `declined`（已拒绝） |
| 移至X月 / 转X月 / 未合作过 | NULL（保留现有阶段） |

唯一键：`(normalized_email, feishu_operator_name)` 复合索引，upsert 时使用。

业务保护：

- `source = 'manual'` 字段不被飞书同步覆盖
- 飞书同步**不**写 `kols.owner_user_id` 的人工修改值
- 同步**只读**，不写回飞书

### 2.4 GmailSyncService（对应 v3.3 §3 同步按钮 + 自动化）

两种模式（与旧版一致）：

| 模式 | 触发 | 单次量 | API 路径 |
|------|------|--------|----------|
| 增量 | 手动或 Cron 每 2～5 分钟 | 50 封 | `history.list` |
| 历史 | 用户首次同步 | 30 封/页，循环 | `messages.list` + `pageToken` |

每页处理：

1. `messages.get(format=full)` × 并发 4
2. 已存在的 `gmail_message_id` 批量跳过 AI
3. 调 `AiService.classifyEmail`
4. `persistGmailSync`：飞书达人过滤后 upsert
5. 更新游标：每页更新 `last_synced_at`；全部分页完成才更新 `last_synced_history_id`

### 2.5 GmailSendService（对应 v3.3 §4）

单发 + 批量 + CC + HTML：

```text
MIME 结构：multipart/alternative
├── text/plain  ← 纯文本 fallback
└── text/html   ← 富文本主体
```

成功后必做：

1. Gmail 返回 messageId 后**立即**写 outbound `emails`
2. 更新 `kols.last_outbound_at`
3. 若使用模板，模板 `used_count++`、`last_used_at`
4. 写 audit log

### 2.6 ScheduledEmailService（对应 v3.3 §9）

状态机：

```
scheduled ──(到点)──▶ processing ──成功──▶ sent
                          │
                          └──失败──▶ failed (attempt<3) ──下次扫描重试──▶ processing
                                  │
                                  └──attempt>=3──▶ failed（终态）
```

原子认领（防重复发送）：

```sql
UPDATE scheduled_emails
SET status='processing', attempt_count=attempt_count+1, last_attempt_at=now()
WHERE id IN (
  SELECT id FROM scheduled_emails
  WHERE status IN ('scheduled', 'failed') AND scheduled_at <= now() AND attempt_count < 3
  ORDER BY scheduled_at
  LIMIT 10
  FOR UPDATE SKIP LOCKED
)
RETURNING *;
```

Cron 每 1 分钟扫描（替代旧版每天一次）。

### 2.7 TeamService（对应 v3.3 §7）

角色：`leader` / `member` / `intern`

操作：

- 保存设置（角色、mentor、`feishu_operator_name`）
- 保存运营名后**批量归属**：
  ```sql
  UPDATE kols SET owner_user_id = :userId
  WHERE feishu_operator_name = :name AND owner_user_id IS NULL;
  ```
- 标记离职：
  - `profiles.status = 'departed'`
  - 名下 `kols.status` 改为 `orphaned`
- Leader 分配：分配 `orphaned` 达人给指定成员

权限守卫：`@PreAuthorize("hasRole('LEADER')")` + `assertLeader()`。

### 2.8 AiService（详见 04 阶段）

四个能力：

| 方法 | 模型 | 备注 |
|------|------|------|
| `classifyEmail` | moonshot-v1-8k | JSON schema 输出 |
| `generateReplyDraft` | moonshot-v1-128k | 中英双版 |
| `checkDraft` | moonshot-v1-8k | 发送前自检 |
| `translateText` | moonshot-v1-128k | 中英互译 |

Prompt 从旧 `lib/ai/prompts.ts` 迁入 `resources/prompts/*.st`。

降级（无 API Key 或 API 调用失败）：

- `classify` → 正则 heuristic
- `draft` → 模板化 fallback
- `translate` → 提示「未配置」
- `check` → 返回空 issues

## 三、REST API 设计

统一前缀 `/api/v1`，与现有前端 fetch 路径尽量对齐。

### 工作台 / KOL / Email

| Method | Path | 说明 |
|--------|------|------|
| GET | `/api/v1/workbench` | 工作台数据（列表 + 统计） |
| GET | `/api/v1/kols/{kolId}` | KOL 详情 + 邮件时间线 |
| PATCH | `/api/v1/kols/{kolId}` | 改名 / 校准阶段 / 标记无需回复 |
| POST | `/api/v1/kols/assign` | Leader：分配离职遗留 |
| PATCH | `/api/v1/emails/{emailId}` | 标记已读 / 未读 |
| DELETE | `/api/v1/emails/{emailId}` | 删除邮件 |
| POST | `/api/v1/emails/{emailId}/reclassify` | 重新 AI 分类 |

### 看板 / 团队 / 模板 / 定时

| Method | Path | 说明 |
|--------|------|------|
| GET | `/api/v1/board` | 看板 KPI + 漏斗 + 阶段分布 |
| GET | `/api/v1/team/members` | 团队成员列表 |
| PATCH | `/api/v1/team/profile` | 编辑个人资料 |
| POST | `/api/v1/team/depart/{userId}` | Leader：标记离职 |
| GET | `/api/v1/templates` | 我的模板列表 |
| POST | `/api/v1/templates` | 新建 |
| PATCH | `/api/v1/templates/{id}` | 编辑 |
| DELETE | `/api/v1/templates/{id}` | 删除 |
| GET | `/api/v1/scheduled-emails` | 定时邮件列表 |
| POST | `/api/v1/scheduled-emails` | 创建排程 |
| DELETE | `/api/v1/scheduled-emails/{id}` | 取消（仅未发送） |

### 同步 / 发信 / AI

| Method | Path | 说明 |
|--------|------|------|
| POST | `/api/v1/sync/gmail` | 触发 Gmail 同步（mode=incremental/history，支持 pageToken） |
| GET | `/api/v1/sync/gmail/status` | 同步进度 |
| POST | `/api/v1/sync/feishu` | 触发飞书同步 |
| POST | `/api/v1/gmail/send` | 单发邮件 |
| POST | `/api/v1/gmail/batch-send` | 批量跟进 |
| POST | `/api/v1/ai/classify` | AI 邮件分类 |
| POST | `/api/v1/ai/draft` | AI 草稿生成 |
| POST | `/api/v1/ai/check` | AI 草稿自检 |
| POST | `/api/v1/ai/translate` | 中英互译 |

### 认证

| Method | Path | 说明 |
|--------|------|------|
| GET | `/oauth2/authorization/google` | 平台登录（Spring Security 自带） |
| GET | `/login/oauth2/code/google` | OAuth 回调 |
| GET | `/api/v1/gmail/authorize` | 单独 Gmail 邮箱授权 |
| POST | `/api/v1/auth/logout` | 退出 |

详见 `api-contract-v1.yaml`（按 Phase 增量填充）。

## 四、数据库 Schema

### 4.1 沿用旧 schema 主体

旧仓库 `supabase/migrations/001~010` 全部转为 Flyway 脚本（`V1__init.sql`～`V10__perf_indexes.sql`）。

核心表：

- `profiles`（用户扩展）
- `kols`（达人）
- `emails`（邮件）
- `email_templates`（模板）
- `scheduled_emails`（定时邮件）
- `actions`（审计日志）

### 4.2 新增表 / 字段

```sql
-- 多租户
CREATE TABLE tenants (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  plan TEXT NOT NULL DEFAULT 'lovart_internal',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 集成凭证（加密存储）
CREATE TABLE integration_credentials (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  user_id UUID REFERENCES profiles(id),  -- Gmail 是 per-user，飞书是 per-tenant
  type TEXT NOT NULL,                    -- 'google' / 'feishu' / 'kimi'
  encrypted_payload BYTEA NOT NULL,      -- 加密后的 JSON
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 同步任务（Worker 用）
CREATE TABLE sync_jobs (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  user_id UUID,
  type TEXT NOT NULL,           -- 'gmail.incremental' / 'gmail.history' / 'feishu.delta'
  payload JSONB,
  status TEXT NOT NULL,         -- 'pending' / 'running' / 'done' / 'failed'
  attempt_count INT DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ
);
CREATE INDEX idx_sync_jobs_pending ON sync_jobs (status, created_at) WHERE status='pending';

-- AI 使用记录
CREATE TABLE ai_usage_log (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL,
  user_id UUID,
  capability TEXT NOT NULL,
  model TEXT,
  prompt_tokens INT,
  completion_tokens INT,
  duration_ms INT,
  success BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 4.3 索引保留

```sql
idx_emails_user_sent       (user_id, sent_at DESC)
idx_kols_owner_created     (owner_user_id, created_at DESC)
kols_email_operator_uidx   (normalized_email, feishu_operator_name)
idx_kols_feishu_operator_name (feishu_operator_name)
```

## 五、ORM 选型

**统一使用 MyBatis-Plus 3.5+ + Flyway**，禁止混入 JPA / Hibernate。详细决策见 [ADR-006](./decisions/ADR-006-orm-mybatis-plus.md)。

### 5.1 场景映射

| 场景 | 实现方式 |
|------|---------|
| 简单 CRUD（按主键查询、保存、删除） | `BaseMapper<T>` 内置方法 |
| 单表条件查询、分页 | `LambdaQueryWrapper` + `PaginationInnerInterceptor` |
| 多表 JOIN、聚合（工作台筛选、看板漏斗） | `Mapper.xml` 写原生 SQL（CTE、窗口函数自由使用） |
| 批量 upsert（Gmail 同步、飞书同步） | `Mapper.xml` `<foreach>` + PG `ON CONFLICT ... DO UPDATE` |
| 定时邮件原子认领 | `Mapper.xml` `UPDATE ... WHERE status='scheduled' ... RETURNING ...` |
| 多租户 `tenant_id` 过滤 | `TenantLineInnerInterceptor` 自动注入（无需手写） |
| 软删除 | `@TableLogic` 自动追加 `deleted_at IS NULL` |
| 审计字段（`created_at` 等） | `MetaObjectHandler` 自动填充 |
| 乐观锁 | `@Version` + `OptimisticLockerInnerInterceptor` |

### 5.2 PG 特有类型映射（TypeHandler）

放在 `maildesk-common/typehandler/`，全项目共享：

| 类型 | TypeHandler |
|------|------------|
| `JSONB`（AI 输出、Gmail headers、`actions.metadata`） | `JsonbTypeHandler` |
| `TEXT[]`（`to_emails`、`cc_emails`、`feishu_tags`） | `StringArrayTypeHandler` |
| PG `ENUM`（`kol_stage` 等） | `PgEnumTypeHandler<E>` |
| `UUID` | MyBatis 默认支持 |
| `timestamptz` | MyBatis 默认支持（映射 `OffsetDateTime`） |

### 5.3 关键基础设施类（`maildesk-infrastructure/.../config/`）

- `MyBatisPlusConfig` — 注册 Interceptor 链路（多租户、分页、乐观锁）
- `AuditFieldFiller`（实现 `MetaObjectHandler`） — 自动填充 `created_at` / `updated_at` / `created_by` / `updated_by`
- `TenantLineHandler` — 从 `TenantContext` 取当前租户，单租户期返回固定值
- `JsonbTypeHandler`、`StringArrayTypeHandler` — 通过 `@Configuration` 注册全局生效

### 5.4 不引入的依赖

- `spring-boot-starter-data-jpa`
- `hibernate-core`
- `hibernate-types-*`
- `spring-jdbc` 仅作为 MyBatis 间接依赖存在，业务代码**不直接使用 `JdbcTemplate`**（特殊场景例外，需注释说明原因）

## 六、Worker 独立进程

`maildesk-worker` 是独立的 `@SpringBootApplication`，不暴露 HTTP（或只暴露 actuator）。

任务列表：

| Job | 频率 | 说明 |
|-----|------|------|
| `GmailIncrementalSyncJob` | 每 2～5 分钟 | 按 `last_synced_at` 排序取 N 个用户 |
| `GmailHistorySyncJob` | 用户触发 | 多页任务入队，串行/并发消费 |
| `FeishuDeltaSyncJob` | 每 30 分钟 | 小批量 50 条 |
| `ScheduledEmailDispatchJob` | 每分钟 | 原子认领、最多 3 次重试 |
| `GmailWatchRenewJob` | 每天（Phase 7） | 续订 Gmail Push watch |

分布式锁：`Redisson` 或 Spring `ShedLock`。

## 七、安全与合规

- OAuth Token：AES-256 加密存储 `integration_credentials.encrypted_payload`
- 密钥管理：AWS Secrets Manager / Vault（生产）
- 日志：禁止打印 Token、邮件正文、AI Prompt 全文
- 审计：所有写操作通过 `AuditLogger`，写 `actions` 表（append-only）
- 限流：Spring Cloud Gateway 或 Bucket4j，按 tenant 限流

## 八、可观测性

- 日志：Logback JSON，输出到 stdout，由 Loki 收集
- Metrics：Micrometer + Prometheus，关键指标：
  - `gmail.sync.duration` (histogram)
  - `gmail.sync.failed` (counter, by user)
  - `ai.classify.tokens` (counter)
  - `scheduled_email.dispatch.lag_seconds` (gauge)
- Tracing：OpenTelemetry SDK，对接 Tempo/Jaeger
- 告警：
  - Gmail 同步连续 3 次失败 → 通知 leader
  - AI 失败率 > 20% → 告警
  - 定时邮件 dispatch lag > 5 分钟 → 告警
