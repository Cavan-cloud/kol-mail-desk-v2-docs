# 生产切流 Runbook（P6-T11）

> **变更类型**：Major — DNS / 前端托管 / API Ingress 切换  
> **维护窗口**：建议 UTC+8 **02:00–04:00**（业务低峰）  
> **预计时长**：30–60 分钟（含 10 分钟禁写）  
> **前置**：[`dual-run-drill.sh`](./dual-run-drill.sh) 自动项全绿 + manual gates 已勾选 + 双跑 ≥14 天

---

## 角色（RACI）

| 角色 | 职责 |
|------|------|
| **变更负责人（TL）** | 宣布开始/结束、Go/No-Go、回滚决策 |
| **后端 On-call** | K8s Helm upgrade、API/Worker 健康、迁移最终 diff |
| **前端 On-call** | Vercel 环境变量 / 域名切换 |
| **业务代表** | 禁写期间确认无紧急发信；切流后 spot check |

---

## 切流前 24h 检查清单

- [ ] `./dual-run-drill.sh` 最近一次运行 PASS（归档日志）
- [ ] `migration/diff.sh` 绿
- [ ] `05-feature-parity.md` 无 `[ ]`
- [ ] Prometheus 告警已部署（`deploy/prometheus/alerts/maildesk.rules.yml`）
- [ ] Secrets 已注入（External Secrets + 云 SM · 见 `deploy/secrets/README.md`）
- [ ] 回滚 Runbook 已读：[`rollback-runbook.md`](./rollback-runbook.md)
- [ ] 业务公告：切流窗口 + 10 分钟禁写
- [ ] 旧系统备份：Supabase snapshot / PITR 点确认

---

## 切流窗口时间线

### T-30min — 冻结与备份

1. 确认无进行中的批量发信 / 定时邮件 dispatch
2. Supabase：**禁止新 DDL**；确认可只读连接串可用（回滚用）
3. 新 PG：确认 Flyway 版本与 staging 一致

### T-10min — 禁写旧系统

1. **旧 Vercel**：部署 maintenance 或 Feature Flag 禁写（发信 / KOL 编辑 / 同步按钮灰掉）  
   - 若无法快速禁写：业务口头确认 10 分钟内无人操作
2. 等待旧 Worker / Cron 队列排空（legacy 如有）

### T0 — 最终数据同步

```bash
cd kol-mail-desk-v2-docs/scripts/migration
ENV_FILE=.env.migration ./migrate.sh
ENV_FILE=.env.migration ./migrate-google-credentials.sh   # 若尚未跑
ENV_FILE=.env.migration ./diff.sh | tee cutover-final-diff.log
```

**Go/No-Go**：`diff.sh` 必须 exit 0。失败 → **立即中止切流**，见回滚 Runbook §「切流前失败」。

### T+5min — 切换后端入口

1. **DNS / Ingress**：`api.<domain>` CNAME → 新 K8s Ingress LB  
   ```bash
   helm upgrade --install maildesk deploy/helm/maildesk \
     --namespace maildesk \
     -f deploy/helm/maildesk/values.yaml \
     --set config.corsAllowedOrigins=https://app.<domain> \
     --set config.webRedirectUrl=https://app.<domain>/ \
     --set ingress.enabled=true \
     --set ingress.hosts[0].host=api.<domain>
   ```
2. 验证：`curl -sf https://api.<domain>/actuator/health`

### T+10min — 切换前端

1. **Vercel（新前端 repo `kol-mail-desk-v2-web`）**：
   - Production 域名 `app.<domain>` 指向新 project
   - 环境变量 `NEXT_PUBLIC_API_BASE_URL=https://api.<domain>`
2. 验证：浏览器打开 `/login` → OAuth 回调成功

### T+15min — 冒烟（生产）

| # | 动作 | 期望 |
|---|------|------|
| 1 | Google 登录 | 进入工作台 |
| 2 | Gmail 手动同步 | 202 + 进度完成 |
| 3 | 打开任一 KOL 详情 | 邮件时间线正常 |
| 4 | 发测试邮件（自发自收） | [`gmail-send-smoke.md`](../gmail-send-smoke.md) |
| 5 | 创建 5min 后定时邮件 | 状态 → sent |
| 6 | AI 翻译按钮 | 返回中文 |

### T+30min — 切流后 diff

```bash
ENV_FILE=.env.migration ./diff.sh
```

允许邮件总数 ±5（切流窗口内新邮件）；**KOL latest gmail_message_id 仍为零容差**。

若 diff 失败或冒烟未过 → **评估回滚**（[`rollback-runbook.md`](./rollback-runbook.md)）。

### T+60min — 宣布完成

1. 解除旧系统禁写 → 改为 **只读保留 14 天**（Supabase 不删）
2. 发送切流完成通知
3. 开启加强监控 24h（Gmail / AI / dispatch 告警）

---

## 切流 drill（dry-run，不改 DNS）

用于 P6-T11 验收，**不得**在生产域名执行：

1. 使用 **staging 域名** 完整走一遍 T0–T+30min 步骤
2. 运行 `./dual-run-drill.sh`，`DRY_RUN_ONLY=false` 对 **staging TARGET DB**
3. 填写 drill 记录：

| 字段 | 值 |
|------|-----|
| 日期 | |
| 执行人 | |
| staging API URL | |
| migrate + diff 结果 | PASS / FAIL |
| 冒烟 6 项 | PASS / FAIL |
| 发现问题 | |
| 是否批准生产切流 | Go / No-Go |

4. drill 记录存入团队 wiki / 变更单附件

---

## 常见问题

### OAuth 用户大量登录失败

- 检查 `TOKEN_ENCRYPTION_KEY` 与 credential 迁移是否一致
- 临时方案：引导用户「重新授权 Gmail」（P3-T04 banner）
- 若 >30% 用户失败 → 考虑回滚

### 新 Worker 未同步 Gmail

- 检查 Redis 锁、Gmail refresh token、`gmail.sync.failed` 指标
- `kubectl logs deploy/maildesk-worker -n maildesk --tail=200`

### CORS 错误

- 确认 Helm `config.corsAllowedOrigins` 含新前端 origin
- 确认 `webRedirectUrl` 末尾 `/`

---

## 引用

- 数据迁移：[`migration/README.md`](../migration/README.md)
- 风险：[`07-risks.md` R11](../../specs/07-risks.md)
- K8s：[`deploy/k8s/README.md`](../../../kol-mail-desk-v2-backend/deploy/k8s/README.md)
