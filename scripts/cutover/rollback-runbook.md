# 回滚预案 Runbook（P6-T12）

> **目标**：切流后若新系统不可用或数据不一致，**15 分钟内**恢复用户访问旧 Vercel + Supabase。  
> **前提**：切流时旧库已停写但未删除；Supabase 只读保留 **≥14 天**（`07-risks.md` R11）。

---

## 回滚决策矩阵

| 触发条件 | 严重度 | 建议动作 | 决策人 |
|----------|--------|----------|--------|
| `diff.sh` 切流前失败 | — | **中止切流**，不切换 DNS | TL |
| 切流后 30min 内 `diff.sh` KOL latest ID 不一致 | P0 | **立即回滚** | TL |
| 生产登录 / OAuth 大面积失败（>30% 用户） | P0 | **立即回滚** | TL |
| Gmail 同步完全停止 >15min 且无法修复 | P0 | **立即回滚** | TL + On-call |
| 发信失败率 100% 持续 >10min | P0 | **立即回滚** | TL |
| AI 失败率高但核心业务可读写 | P2 | 降级 AI，**不回滚** | TL |
| 非关键 UI 缺陷 | P3 | 热修 forward fix | TL |
| 定时邮件 dispatch lag 告警 | P2 | 先 scale Worker / 查 Redis；30min 未恢复再评估回滚 | On-call |

**回滚口令**：变更负责人在 war room 宣布 **「执行 ROLLBACK-PROD」** 后按下列步骤操作，避免多人重复改 DNS。

---

## RTO / RPO

| 指标 | 目标 | 说明 |
|------|------|------|
| **RTO**（恢复服务） | ≤ 15 min | DNS 切回旧 Vercel + 旧 API |
| **RPO**（数据丢失） | 切流窗口禁写期 + 切流后在新系统产生的写 | 切流后在新 PG 的写操作**不会**自动回灌旧库；回滚后这些写丢失，需人工对账 |

> **重要**：回滚 = 流量回旧系统，**不是**把新 PG 数据反向同步到 Supabase。切流后在 v2 的写操作需业务侧决定是否手工补录。

---

## 回滚步骤（生产）

### 阶段 A — 0–5 min：止损

1. 变更负责人宣布 **ROLLBACK-PROD**
2. **新系统**：Helm scale API/Worker 至 0（或 Ingress 摘流量）
   ```bash
   kubectl scale deployment/maildesk-api deployment/maildesk-worker \
     -n maildesk --replicas=0
   ```
3. **新前端 Vercel**：Production 域名切回 **旧 project**（或 maintenance 页指向旧 URL）

### 阶段 B — 5–10 min：恢复旧入口

1. **DNS**：`app.<domain>` → 旧 Vercel；若 API 独立域名，指回旧 Supabase Edge / legacy API
2. 验证：`curl -I https://app.<domain>` 返回旧系统标识
3. **解除旧库只读 / 禁写**（若切流时启用）

### 阶段 C — 10–15 min：验证

| # | 检查 | 期望 |
|---|------|------|
| 1 | 旧系统登录 | 成功 |
| 2 | 工作台列表 | 数据为切流前快照 + 切流窗口内旧库写入 |
| 3 | Gmail 同步 | 可用 |
| 4 | 发测试邮件 | 成功 |

### 阶段 D — 15 min 后：善后

1. 通知业务：已回滚；切流后在新系统的操作可能丢失
2. 保留新 PG 快照供根因分析（**不删**）
3. 48h 内开 postmortem：根因、diff 差异、修复计划
4. 修复后重新进入双跑期，**不得**跳过 drill

---

## 切流前失败（未切 DNS）

若 T0 `diff.sh` 失败或 migrate 报错：

1. **不要**切换 DNS / Vercel
2. 旧系统继续正常服务
3. 定位 diff 差异：
   ```bash
   ENV_FILE=.env.migration ./diff.sh 2>&1 | tee rollback-pre-cutover.log
   psql "$SOURCE_DATABASE_URL" -f ../migration/sql/diff-source.sql
   psql "$TARGET_DATABASE_URL" -v tenant_id="$DEFAULT_TENANT_ID" \
     -f ../migration/sql/diff-target.sql
   ```
4. 修复迁移 SQL 或等待旧库同步追上后重跑 migrate

---

## 双跑期回滚（staging 失败）

staging 环境异常 **不影响** 生产。处理：

1. 重建 staging namespace / DB
2. 重跑 Flyway + migrate + `dual-run-drill.sh`
3. 不触发本 Runbook 生产步骤

---

## 通信模板

### 切流开始（提前 24h）

```
主题：[Mail Desk] 系统升级窗口 YYYY-MM-DD 02:00–04:00

届时将有约 10 分钟无法发信/编辑达人。请提前完成紧急跟进。
升级后 URL 不变。如有问题请联系 @on-call。
```

### 回滚通知

```
主题：[Mail Desk] 升级回滚 — 服务已恢复

我们已回滚至升级前版本，请刷新页面后继续使用。
升级窗口内（HH:MM–HH:MM）在新版录入的数据可能未保留，请联系 @on-call 对账。
```

---

## 新库清理（仅预发 / 演练）

**禁止**在生产回滚后自动 TRUNCATE 新 PG。仅 **staging / drill** 环境可：

```bash
# 仅限非生产 tenant — 见 migration/README.md
# 按 tenant_id TRUNCATE 业务表 → 重跑 Flyway seed
```

---

## 检查清单（切流前必须签署）

- [ ] 本 Runbook 已分发给 On-call
- [ ] 旧 Vercel project 仍可部署、域名可切回
- [ ] Supabase 连接串有效（只读即可）
- [ ] 回滚决策人（TL）切流窗口在线
- [ ] drill 记录 No-Go 项已关闭

---

## 引用

- 切流步骤：[`cutover-runbook.md`](./cutover-runbook.md)
- 双跑 drill：[`README.md`](./README.md) · [`dual-run-drill.sh`](./dual-run-drill.sh)
- 风险：[`07-risks.md` R8/R11](../../specs/07-risks.md)
