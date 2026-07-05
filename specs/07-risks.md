# 风险与对策

## 一、技术风险

### R1：Gmail 同步语义回归

**风险：** 新 Java 实现与旧 TypeScript `lib/gmail/persist.ts` 行为不一致，导致：

- 已读状态丢失
- 飞书过滤漏掉合法邮件
- 重复入库
- 历史游标错位漏拉

**影响：** 高（直接影响日常使用）

**对策：**

- 移植时逐条对照旧 `persist.ts` 写单元测试
- Phase 3 末期做「双跑 diff」：同一 Gmail 邮箱，旧库与新库同步结果对比
- 关键不变量写 ArchUnit / 业务规则测试：
  - `(gmail_message_id, user_id)` 唯一
  - `isFeishuBacked` 守卫
  - `is_read` UPDATE 路径不变
- 灰度上线：先 1 个测试账号 → 3 个内部账号 → 全员

---

### R2：OAuth Token 迁移

**风险：** 旧 Supabase `profiles.google_refresh_token` 迁移到新 `integration_credentials` 时，加密格式、Scope、有效性可能丢失。

**影响：** 高（用户被强制重新授权）

**对策：**

- 迁移脚本明文导出 → 新库 AES 加密导入
- 迁移完成后批量调一次 `messages.list(maxResults=1)` 验活
- 失活用户在工作台显著提示「重新授权 Gmail」
- 提前周知，迁移当日做用户支持值班

---

### R3：看板聚合性能

**风险：** 1800+ KOL × 多维度聚合 + 时间窗筛选，单次查询超 1s。

**影响：** 中（影响 Leader 体验）

**对策：**

- 看板聚合 SQL 单次返回（避免应用层多次查询）
- Redis 缓存 60s（沿用旧 `BOARD_AGG_TAG`）
- 索引：`(tenant_id, feishu_outreach_at)`、`(owner_user_id, stage)`
- 大租户上线前用真实数据量压测

---

### R4：Spring AI JSON 输出不稳定

**风险：** LLM 偶尔返回非法 JSON、字段缺失、枚举越界，导致同步失败或入库脏数据。

**影响：** 中（AI 失败但邮件不丢）

**对策：**

- Spring AI `response-format: json_object`
- 服务端 Bean Validation + 自定义 enum 校验
- 失败 → `fallbackClassification`（保留邮件，标记「待人工」）
- `ai_usage_log` 记录失败率，超 20% 告警

---

### R5：飞书 API 限流 / 字段变更

**风险：** 飞书 Sheet 多分页 + 多字段读取，可能触发限流；运营手动改飞书表头会导致字段映射失败。

**影响：** 中

**对策：**

- 并发上限：现 3 → 保持
- 字段映射写在配置（`application.yml`），不写死在代码
- 同步前先调一次 `inspect-feishu-sheet` 校验表头（沿用旧脚本）
- 缺失字段写入 `sync_jobs.last_error`，UI 显示，不静默失败

---

### R6：长任务超时（不再有 Vercel 60s）

**风险：** Worker 跑长任务时如果配置不当，仍会被 K8s liveness 杀掉。

**影响：** 中

**对策：**

- Worker 任务必须分页化（沿用旧 `pageToken` 模式）
- K8s liveness 看 Worker 心跳（写 Redis），不看任务时长
- 单任务硬上限 5 分钟，超时自动 mark failed 并入队下一批
- 长任务必须能从游标恢复

---

### R7：多 Worker 重复发送定时邮件

**风险：** Worker HPA 扩容后多副本同时认领同一行。

**影响：** **极高**（重复给客户发邮件）

**对策：**

- `SELECT ... FOR UPDATE SKIP LOCKED` 原子认领
- 状态机：`scheduled → processing → sent`，processing 中无法二次认领
- 集成测试：开 5 个线程并行调用，断言每行只发一次
- 即使发送成功，也要校验 Gmail `messageId` 唯一（DB 加唯一索引）

---

## 二、产品 / 工期风险

### R8：4～5 个月重构期内业务停滞

**风险：** 重构期间旧系统仍需运行，且不能影响业务节奏。

**对策：**

- 旧系统冻结新需求，只接关键 bug fix
- 重构期间紧急 bug 优先在旧仓库修复
- 每个 Phase 末期演示给业务，提前发现偏差
- 切流前留 2 周双跑，便于回滚

---

### R9：工期膨胀

**风险：** 17～22 周可能延期到 25+ 周（依赖外部 API、性能调优、UI 走查）。

**对策：**

- Phase 严格交付，超时不延后 → 拆出「下个 Phase」
- 不在 Phase 1～4 做性能调优（除非 P99 > 5s）
- UI 走查集中在 Phase 5 末期一次性做
- 不做范围外的事：飞书双向、移动端、实时协同（坚决砍）

---

### R10：团队 Java 经验不足

**风险：** Spring Boot / Spring AI / OAuth2 / Testcontainers 学习成本。

**对策：**

- Phase 0 安排团队 stage 0 培训（2 天）
- Phase 1 由 TL 主导框架代码，团队 review 中学习
- 关键集成（Security、Worker、AI）TL review
- 引入 ArchUnit 守住模块边界，降低自由发挥风险

---

## 三、运维风险

### R11：生产数据迁移

**风险：** 切流瞬间 Supabase → 新 PG 数据不一致。

**对策：**

- Phase 6 末期跑 dry run 全量导入
- 凌晨低峰期切流，禁写 10 分钟
- 切流后立即跑 diff 报表（见 06-testing.md §7）
- 旧库保留 2 周只读访问
- 回滚预案：DNS 切回旧 Vercel，旧库已停写但仍可只读

---

### R12：密钥泄漏

**风险：** AES 密钥、Google OAuth Secret、Kimi API Key 泄漏。

**对策：**

- 密钥统一走 Secrets Manager / Vault，不入 git — 见 [`deploy/secrets/README.md`](../../../kol-mail-desk-v2-backend/deploy/secrets/README.md)（P6-T13）
- 日志禁止打印任何密钥（CI 自动检测 `grep -r 'sk-' src/`）
- 定期轮换（季度）
- 离职流程包括撤销访问

---

### R13：依赖漏洞

**风险：** Spring Boot / Next.js / TipTap 等关键依赖出 CVE。

**对策：**

- Dependabot / Renovate 自动 PR
- 每周 1 次 `mvn dependency:tree` + `npm audit` review
- 高危 CVE 24h 内打补丁

---

## 四、决策依赖

如果以下假设不成立，需重新评估方案：

| 假设 | 不成立时影响 |
|------|-------------|
| 团队继续以 Java 为主要后端栈 | 改 NestJS 重写 spec 02-backend-design |
| Kimi/Moonshot 持续可用 | 切 OpenAI / Claude，AI 服务接口不变 |
| PostgreSQL 仍是主库 | 重新评估 ADR-003 |
| 业务方接受 4～5 个月重构期 | 缩减范围到 Phase 1～4，先做骨架 + 飞书同步 |
| 团队人数不少于 3 人 | 工期延长至 8～10 个月 |

---

## 五、风险跟踪机制

- 每个 Phase Kickoff 时回顾本文档
- 新风险加在最后一节，按 R{n} 编号
- 风险触发 / 关闭时更新对策状态
- Phase 6 切流前完整 review 一次
