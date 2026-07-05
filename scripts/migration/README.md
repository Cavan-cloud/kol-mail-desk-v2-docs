# 旧 Supabase → 新 PostgreSQL 数据迁移（P6-T10）
#
# 前置：
#   1. 新库已跑完 Flyway（空业务表 + 默认 tenant）
#   2. 旧库只读连接串（Supabase direct connection，非 pooler 事务模式亦可）
#   3. psql 14+ 与 dblink 扩展权限
#
# 用法：
#   cp env.example .env.migration
#   # 填 SOURCE_DATABASE_URL / TARGET_DATABASE_URL / DEFAULT_TENANT_ID
#   ./migrate.sh
#   ./diff.sh          # 切流前必跑，容差见 specs/06-testing.md § 七
#
# Google OAuth token 可选第二步：
#   ./migrate-google-credentials.sh
#
# ⚠️ 旧库 profiles.google_* 为明文；新库存 AES 加密 integration_credentials。
#    若 token 迁移失败，用户需重新 OAuth 登录（见 specs/07-risks.md R）。

## 迁移顺序

1. `00_extensions.sql` — target 启用 dblink
2. `01_profiles.sql` … `06_actions.sql` — 按 FK 顺序 INSERT … SELECT via dblink
3. `migrate-google-credentials.sh` — 明文 token → AES integration_credentials（可选）
4. `diff.sh` — 行数 / 分布 diff 报表

## 容差（切流门禁）

| 指标 | 容差 |
|------|------|
| 总 KOL 数 | ±1 |
| 各 stage 分布 | ±2 / stage |
| feishu_outreach_at 非空 | ±2 |
| 各成员 owner KOL 数 | ±1 |
| 邮件总数 | ±5 |
| 各 KOL 最新 gmail_message_id | 0 |

超出容差 → **暂停切流**，定位差异后再跑。

## 回滚

迁移脚本仅 INSERT（`ON CONFLICT DO NOTHING`），不 DELETE 旧库。
新库回滚：按 tenant_id TRUNCATE 业务表后重跑 Flyway seed（仅限预发验证环境）。

## 切流（P6-T11 / P6-T12）

双跑演练、生产切流与回滚见 [`../cutover/README.md`](../cutover/README.md)。
