# 测试策略

## 一、测试金字塔

```
        ┌──────────────┐
        │  E2E (10)    │   Playwright，覆盖 v3.3 主路径
        ├──────────────┤
        │ 集成测试(50) │   Testcontainers（PG/Redis）+ Mock Gmail/飞书
        ├──────────────┤
        │ 单元测试(500)│   JUnit 5 + Mockito（后端）/ Vitest（前端）
        └──────────────┘
```

## 二、后端测试

### 2.1 单元测试

**框架：** JUnit 5 + AssertJ + Mockito

**覆盖范围：**

- 领域规则：`needsReply`、`isFeishuBacked`、阶段映射
- 服务编排：mock 集成层，验证调用顺序与去重
- DTO 校验：Spring Validator 边界用例
- 工具方法：邮件解析、HTML 净化、邮箱归一化

**门槛：** Phase 1+ 行覆盖率 ≥ 60%；核心领域类 ≥ 80%。

### 2.2 集成测试

**框架：** Spring Boot Test + Testcontainers

**容器：**

```yaml
- PostgreSQL 16
- Redis 7
```

**覆盖范围：**

- Flyway 全量执行无错
- Repository 关键查询（看板聚合、工作台列表）
- `persistGmailSync` 端到端：飞书过滤、upsert 幂等、`is_read` 不被覆盖
- `processDueScheduledEmails` 原子认领：多线程不重复发
- OAuth Token 加密存取

### 2.3 外部 API 测试

**Gmail / 飞书 / Kimi：**

- 单元：用录制 fixture（JSON）
- 集成：测试账户 + 测试租户，每周自动跑一次
- 不在 PR 必跑里加（避免 quota 消耗）
- **Gmail 发信冒烟（P5-T20）**：`maildesk-integration` 模块 `GmailSendSmokeTest`，需 `GMAIL_SMOKE_ACCESS_TOKEN` + `GMAIL_SMOKE_TO`；运行手册见 [`scripts/gmail-send-smoke.md`](./scripts/gmail-send-smoke.md)

**Mock Server：** WireMock 或自建 `FakeGmailClient`。

### 2.4 性能测试

| 接口 | 目标 |
|------|------|
| `GET /api/v1/workbench` | P95 < 500ms（5000 KOL） |
| `GET /api/v1/board` | P95 < 1s（缓存命中 < 100ms） |
| Gmail 增量同步单用户 | P95 < 20s（50 封） |
| AI classify 单次 | P95 < 8s |

工具：Gatling 或 k6。

## 三、前端测试

### 3.1 单元测试

**框架：** Vitest + Testing Library

**覆盖：**

- 纯函数（`workbench.ts`、`domain.ts`）
- 关键 hook（自定义 useQuery 包装）
- 关键组件状态机（`DraftSendPanel`、`GmailSyncButton`）

### 3.2 视觉回归

**工具：** Playwright Screenshot Diff 或 Chromatic（如有预算）

**关键截图：**

- 工作台（三视图 × 三状态）
- 看板（漏斗 / 阶段分布）
- 草稿面板
- 团队页面
- 模板编辑

## 四、E2E 测试

**框架：** Playwright

**10 条核心路径：**

1. 登录 → 进入工作台 → 看到 KOL 列表
2. 搜索 Ctrl+K → 选中达人 → 查看邮件
3. 标记无需回复 → 「需我回复」数字 -1 → 取消无需回复
4. 写草稿（富文本 + CC）→ 发送 → outbound 出现
5. AI 生成草稿 → 翻译 → 自检 → 修改后发送
6. 批量跟进：多选 → 选模板 → 发送 → 全部成功
7. 看板时间窗切换：本周 → 本月 → 指定月份
8. 看板模式切换：累计漏斗 ↔ 阶段分布
9. 团队页面：保存运营名 → 名下达人数量更新
10. 定时邮件：保存 → 列表显示 → 取消

## 五、按 v3.3 场景的回归清单

| 场景 | 验收点 |
|------|--------|
| 新人上手 §2 | 填飞书运营名 → 自动归属达人 |
| 工作台 §3 | 需我回复/等待对方/未读/高优先级标签正确 |
| 打开主页 | 外链跳转正常 |
| 标记无需回复 | 下一封 inbound 自动清除 |
| 富文本发信 §4 | multipart/alternative + CC |
| 看板 §5 | 月份筛选依赖 feishu_outreach_at |
| 漏斗 | 累计 vs 分布两种模式数字正确 |
| 阶段 §6 | 飞书「已询价」→ 触达，「议价中」→ 沟通/议价 |
| 离职 §7 | orphaned → Leader 分配 |
| 定时 §9 | 取消、重试、不重复发送 |
| FAQ §10 | 陌生人邮件不入库；AI 失败仍入库 |

## 六、CI 流程

### 6.1 后端 CI

```yaml
on: [push, pull_request]
jobs:
  build:
    - mvn -B -DskipTests verify
    - mvn -B test
    - mvn -B verify -Pintegration   # 含 Testcontainers
  archunit:
    - mvn -B test -Dtest=ArchUnitTest  # 模块依赖方向
  openapi-lint:
    - npx @redocly/cli lint specs/api-contract-v1.yaml
  flyway-check:
    - mvn flyway:validate
```

### 6.2 前端 CI

```yaml
on: [push, pull_request]
jobs:
  build:
    - npm ci
    - npm run lint
    - npm run typecheck
    - npm run test
    - npm run build
  e2e:
    - npx playwright test
```

## 七、数据迁移验证（Phase 6）

切流前必须跑的 diff 报表：

| 指标 | 校验方式 | 容差 |
|------|---------|------|
| 总 KOL 数 | SQL COUNT 旧 vs 新 | ±1 |
| 各阶段分布 | 分组 COUNT | ±2 per stage |
| `feishu_outreach_at` 有日期数 | COUNT WHERE NOT NULL | ±2 |
| 各成员名下 KOL 数 | GROUP BY owner_user_id | ±1 |
| Gmail 邮件总数 | COUNT | ±5 |
| 各 KOL 最新邮件 ID | LEFT JOIN diff | 0 |

容差超出 → 暂停切流，定位差异。

自动化 drill 脚本：[`scripts/cutover/dual-run-drill.sh`](../scripts/cutover/dual-run-drill.sh)（含 feature-parity 与 diff 门禁）。切流步骤见 [`scripts/cutover/cutover-runbook.md`](../scripts/cutover/cutover-runbook.md)。

## 八、安全与合规测试

- OAuth Token 不在日志中（`grep -r 'access_token' logs/`）
- RLS 启用后跨租户查询返回 0 行（Phase 7）
- HTTP 接口必须 HTTPS（生产）
- CSP / HSTS / X-Frame-Options header
- 邮件正文 HTML 净化（XSS 注入测试）
- 依赖漏洞扫描：`mvn dependency:tree` + `npm audit`
