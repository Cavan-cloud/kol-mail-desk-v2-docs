# v3.3 功能验收工作表（Parity Acceptance Worksheet）

> 生成日期：2026-07-03 · **最后验收批次：2026-07-05（飞书+Gmail 历史 · lauren@lovart.ai）**  
> 来源清单：[`05-feature-parity.md`](./05-feature-parity.md)  
> 切流门禁：`rg "^- \[ \]" specs/05-feature-parity.md` → **0 行**（`[⚠️]` / `[🚫]` 可保留）

---

## 一、汇总（Agent 已自动执行部分）

| 检查项 | 命令 / 方式 | 结果 | 说明 |
|--------|-------------|------|------|
| 前端单元测试 | `pnpm test` | ✅ **23/23 通过** | batch-followup / forbidden-legacy / http / draft-send |
| 前端类型检查 | `pnpm typecheck` | ✅ 通过 | |
| 阶段映射单测 | `mvn -pl maildesk-common test -Dtest=FeishuStageMapperTest` | ✅ 通过 | 10 阶段 v3.3 §6 |
| OAuth scope 配置 | 读 `application.yml` | ✅ 已配置 | `gmail.readonly` + `gmail.send` |
| 导航 5 项 | 读 `AppNav.tsx` `APP_NAV` | ✅ 代码存在 | 工作台/看板/团队/模板/定时 |
| Ctrl+K 搜索 | 读 `WorkbenchSearch.tsx` | ✅ 代码存在 | metaKey/ctrlKey + k |
| 三种 view | 读 `domain.ts` `VIEW_MODES` | ✅ mine/pool/all | UI 三按钮已接 |
| 列表 7 字段 | 读 `KolListRow.tsx` | ✅ 代码存在 | 名/主题/摘要/阶段/负责人/工作流/优先级 |
| DOMPurify | 读 `EmailBodyViewer.tsx` + `package.json` | ✅ 依赖+调用存在 | 无 dedicated 单测 |
| 翻译按钮 | 读 `EmailBodyViewer.tsx` | ✅ 按需 `POST /ai/translate` | |
| 模板单发 | 读 `DraftSendPanel.tsx` | ✅ 下拉选模板+插入 | |
| 批量跟进模板 | 读 `BatchFollowupButton.tsx` | ✅ **已实现** | 模板下拉 + 预览 + 确认勾选（2026-07-04 验收） |
| 看板漏斗 UI | 读 `BoardPipelinePanel.tsx` | ✅ funnel/snapshot 切换 | |
| 看板时间窗后端 | 读 `BoardWindow.java` | ✅ 含 `yyyy-MM` | |
| 看板时间窗前端 | 读 `BoardPage.tsx` | ⚠️ 仅 4 项 | 缺「指定月份」选择器 |
| 看板 KPI 前端 | 读 `BoardPage.tsx` | ⚠️ 标签与 v3.3 不一致 | 见 F-BOARD-KPI |
| 侧栏统计 | 读 `WorkbenchPage.tsx` | ⚠️ 与 v3.3 不一致 | 「未读」替代「高优先级」 |
| onboarding mentor | 读 `onboarding/page.tsx` | ❌ **缺 mentor 字段** | F-AUTH-04 |
| 团队成员指标 | 读 `TeamMemberDto.java` | ⚠️ 仅 `ownedKolCount` | 缺已成交/停滞风险 |
| Feature parity 未勾 | `grep "^- \[ \]"` | **见 §七批次** | 2026-07-04 本地已验 24+ 项；飞书阻塞 6 项；B 类缺口标 ⚠️ |
| 飞书同步 | — | ✅ **2026-07-05** | 飞书个人版 Sheet + 运营名「潘慧妍」归属 |

---

## 二、分类说明（你怎么验收）

| 类型 | 含义 | 你要做什么 |
|------|------|------------|
| **A** | 代码已有，需人工点 UI/API 确认 | 按「操作步骤」走一遍，打 ✅ |
| **B** | 已发现缺口，需先小改代码再验收 | 开发补 PR → 再按步骤验收 |
| **C** | 运维/GCP 配置，非代码 | 控制台截图 / checklist |
| **D** | 必须 staging + 真实 OAuth/Gmail/飞书 | 联调环境执行 |

**推荐顺序**：先扫完所有 **A**（快）→ 排 **B** 开发 → **C/D** 在 staging 集中做 → 更新 `05-feature-parity.md` → 跑 `dual-run-drill.sh`。

---

## 三、逐条验收表

状态列：`⬜待验` / `✅通过` / `⚠️有缺陷` / `🚫不做` / `🤖代码已确认`

### §1 登录与入职

| ID | 功能 | 类型 | 自动/代码 | 操作步骤（你来做） | 状态 |
|----|------|------|-----------|-------------------|------|
| F-AUTH-01 | Google OAuth + Gmail scope | D | 🤖 scope 在 yml | 1) staging 点 Google 登录 2) 同意屏见 gmail 读/发 3) 进工作台 4) DB `integration_credentials` 有加密 token | ✅ **本地 2026-07-04**（staging 待 kolmail.top） |
| F-AUTH-02 | 登录页提示「邮箱权限必须勾选」 | B | ⚠️ 有授权说明但无原话 | 登录页是否**明确写**须勾选 Gmail 权限；GCP 同意屏 brand 已配 | ⬜ |
| F-AUTH-03 | GCP Test users 白名单 | C | — | GCP Console → OAuth consent → Test users 列表截图；非白名单账号应失败 | ⬜ |
| F-AUTH-04 | 首次资料：显示名/角色/mentor/飞书运营名 | B | ⚠️ onboarding 无 mentor；**保存跳转已修** | 新账号 `/onboarding` 填飞书运营名 → 保存进工作台 | ⚠️ **2026-07-05** mentor 仍缺 |

已 ✅ 可跳过：F-AUTH-05、F-AUTH-06

---

### §2 工作台

| ID | 功能 | 类型 | 自动/代码 | 操作步骤 | 状态 |
|----|------|------|-----------|----------|------|
| F-WB-NAV-01 | 5 项导航 | A | 🤖 `APP_NAV` | 未登录访问 `/board` 等应 redirect `/login`；5 链接路由正确 | ✅ 2026-07-04 |
| F-WB-SIDE-01~04 | 侧栏：需我回复/高优先级/团队池/总达人 | B | ⚠️ 现为需我回复/**未读**/团队池/总达人 | 对比 v3.3：是否接受「未读」替代「高优先级」，或补第 4 项统计 | ⚠️ 功能可用；口径待产品确认；侧栏「需我回复」计数与列表标签曾不一致 |
| F-WB-SEARCH-01 | Ctrl+K / Cmd+K | A | 🤖 已实现 | 工作台按快捷键，焦点到搜索框；ESC 可失焦 | ✅ 2026-07-04 |
| F-WB-SEARCH-02 | 搜索匹配多字段 | A | 🤖 后端 `?q=` | 搜达人名、邮箱、主题、摘要各试 1 条；≤30 条、速度可接受 | ✅ 2026-07-04（Ctrl+K + `?q=`） |
| F-WB-LIST-01 | 我的/团队池/全部 | A | 🤖 三 view | 切换 view，列表数量与负责人逻辑正确 | ✅ 2026-07-04 |
| F-WB-LIST-02 | 列表 7 字段 | A | 🤖 `KolListRow` | 抽 3 行目视 7 字段；AI 失败时摘要占位 | ✅ 2026-07-04 |
| F-WB-LIST-03 | 10 阶段标签 | A | 🤖 `KOL_STAGES` 10 项 | 飞书同步达人阶段标签与 §6 一致 | ✅ **2026-07-05** 飞书 Sheet 联调 |
| F-WB-DETAIL-01 | 详情 10 字段 | B | ⚠️ 缺「合作状态」展示 | 打开详情核对：名/邮箱/来源/平台/类型/负责人/报价/主页/备注；`status` 未展示 | ⚠️ 9/10 字段已验；缺 `status` 展示 |
| F-WB-DETAIL-04 | 打开主页 | A | 🤖 有 `externalProfileUrl` | 有链接时按钮可开新 tab；无链接时不显示 | ✅ 2026-07-04 |
| F-WB-EMAIL-01 | HTML 渲染 | A | 🤖 sanitize + render | 找含链接/图片/列表的 inbound 邮件目视 | ✅ 2026-07-04 |
| F-WB-EMAIL-02 | 历史回复折叠 | A | 🤖 `<details>` 引用块 | 长链邮件点「显示历史回复」 | ✅ 2026-07-04（含翻译后折叠） |
| F-WB-EMAIL-03 | DOMPurify 净化 | A | 🤖 allowlist | 可选：dev 插入 `<script>` fixture 确认被剥（或信代码审查） | ✅ 代码审查 + 依赖存在 |
| F-WB-EMAIL-04 | 按需翻译 | A | 🤖 按钮+API | 默认原文；点「翻译成中文」才请求；同步不会自动填 body_zh | ✅ 2026-07-04（Moonshot） |

已 ✅ 可 spot check：F-WB-SYNC-*、F-WB-STATE-*、F-WB-DETAIL-02/03

---

### §3 看板

| ID | 功能 | 类型 | 自动/代码 | 操作步骤 | 状态 |
|----|------|------|-----------|----------|------|
| F-BOARD-KPI | 总达人/待回复·停滞/未读/合作·转化率 | B | ⚠️ UI：总达人/进行中/已发布/转化率 | 与旧系统或业务确认口径；可能要改 KPI 卡片文案与字段 | ⚠️ 数字可见；文案/口径与 v3.3 不一致 |
| F-BOARD-WINDOW | 6 种时间窗 | B | 后端支持 `yyyy-MM`；UI 仅 4 项 | 测 全部/本周/本月/30天；**补月份选择器**或 API 手测 `?window=2026-06` | ⚠️ 4 项 UI 已验；缺月份选择器 |
| F-BOARD-WINDOW | 基于 feishu_outreach_at | A | 🤖 `BoardWindow.matches` | 选「本月」只有 outreach 在本月的达人 | 🚫 待飞书 Sheet + outreach 日期 |
| F-BOARD-WINDOW | 无日期只在「全部」 | A | 🤖 null 不匹配非 all | 无 outreach 日期的达人仅在「全部时间」出现 | 🚫 待飞书数据 |
| F-BOARD-PIPELINE | 累计漏斗 / 阶段分布 / UI 切换 | A | 🤖 `BoardPipelinePanel` | 切换两种模式，副标题变化，漏斗单调递减 | ✅ 2026-07-04 |
| F-BOARD-RATIO | 回复率/转化率/仅漏斗显示 | A | 🤖 计算在 BoardPage | 快照模式不显示比率；漏斗模式显示 | ✅ 2026-07-04 |

---

### §4 团队

| ID | 功能 | 类型 | 自动/代码 | 操作步骤 | 状态 |
|----|------|------|-----------|----------|------|
| F-TEAM-LIST | 成员字段展示 | A | 🤖 Team 表已有多列 | 姓名/邮箱/状态/角色/mentor/飞书运营名目视 | ✅ 2026-07-04 |
| F-TEAM-LIST | 在跟/已成交/停滞风险 | B | ❌ DTO 无字段 | 需后端补指标 + 前端列；或标 ⚠️ 首版不做 | ⚠️ 首版未实现 |
| F-TEAM-OP | 飞书运营名自动归属 | A | ✅ F-AUTH-05 | 保存运营名后「我的」可见对应达人 | ✅ **2026-07-05** |
| F-TEAM-OP | Leader 团队池分配 | A | 🤖 `POST /kols/assign` | 池内 unassigned/orphaned 可分配 | ✅ 2026-07-04 |

已 ✅：F-TEAM-OP 其余项

---

### §5 模板

| ID | 功能 | 类型 | 自动/代码 | 操作步骤 | 状态 |
|----|------|------|-----------|----------|------|
| F-TPL-05 | 撰写/批量跟进可选模板 | B | 单发✅ 批量✅ | DraftSendPanel 选模板插入；BatchFollowup 模板下拉+预览 | ✅ 2026-07-04 |

已 ✅：F-TPL-01～04、06

---

### §6 FAQ / 迁移

| ID | 功能 | 类型 | 自动/代码 | 操作步骤 | 状态 |
|----|------|------|-----------|----------|------|
| F-FAQ-01 | 月份筛选口径 | A | 同看板时间窗 | 与 F-BOARD-WINDOW 一并验收 | 🚫 待飞书 |
| F-FAQ-02 | 迁移期噪音达人清理 | C/D | P6-T10 脚本已有 | 迁移后 SQL 查无主/无邮件 KOL；业务决定是否手工删 | ⬜ |

已 ✅：F-FAQ-03、04

---

## 四、必须修/决策的 B 类缺口（建议 ticket）

| 优先级 | 项 | 建议 |
|--------|-----|------|
| P0 | F-AUTH-04 mentor | onboarding 增加 mentor 选择（实习生必选） |
| P0 | F-TPL-05 批量模板 | `BatchFollowupButton` 增加模板选择+渲染 |
| P1 | F-AUTH-02 文案 | 登录页补「Gmail 邮箱权限须全部勾选」 |
| P1 | F-BOARD-KPI 口径 | 与产品确认：改 UI 对齐 v3.3，或文档标 ⚠️ |
| P1 | F-WB-SIDE 高优先级 | 补侧栏「高优先级」统计，或文档标 ⚠️ 用未读替代 |
| P2 | F-BOARD-WINDOW 月份 | Board 页增加 `yyyy-MM` 月份选择 |
| P2 | F-WB-DETAIL-01 合作状态 | 详情展示 `kol.status` |
| P2 | F-TEAM-LIST 指标 | 后端补 closed/stalled 计数 + 前端列 |
| 决策 | F-TEAM-LIST / 看板 Pool 规则 | 第三条 stalled 规则：实现或 🚫+原因 |

---

## 五、真实切流 drill（与 parity 分开）

parity 清零后，在 **staging** 执行：

```bash
cd kol-mail-desk-v2-docs/scripts/cutover
cp env.example .env.cutover   # 填 staging URL + MIGRATION_ENV
./dual-run-drill.sh           # 自动项
```

| # | 人工项 | 通过标准 |
|---|--------|----------|
| 1 | Google 登录 | F-AUTH-01 在 staging 通过 |
| 2 | Gmail 同步 | 202 + 进度完成，无持续 failed 告警 |
| 3 | 飞书同步 | 202 + KOL 数合理 |
| 4 | 发信冒烟 | [`gmail-send-smoke.md`](../scripts/gmail-send-smoke.md) |
| 5 | 定时邮件 | 创建 5min 后 → sent |
| 6 | AI 四能力 | classify / draft / check / translate 各 1 次 |

完整步骤：[`cutover-runbook.md`](../scripts/cutover/cutover-runbook.md)（**dry-run 不改 DNS**）

---

## 六、验收完成后

1. 更新 [`05-feature-parity.md`](./05-feature-parity.md) 每条 `[ ]` → `[✅]` / `[⚠️]` / `[🚫]`
2. `rg "^- \[ \]" specs/05-feature-parity.md` → 0
3. 同步 [`STATUS.md`](./STATUS.md)（若开新 ticket 修 B 类）
4. staging 跑 `dual-run-drill.sh` 归档日志
5. 业务 sign-off → 生产切流窗口

---

## 七、验收批次 2026-07-04（本地 · 验收人：kaifeng）

**环境**：Docker PG+Redis · 后端 `:8080` · 前端 `:3000` · Google OAuth · Moonshot AI · dev seed  
**阻塞**：飞书 KOL 测试表未提供 → 飞书同步 / 运营名归属 / outreach 时间窗 暂不验

| ID | 结果 | 备注 |
|----|------|------|
| F-AUTH-01 | ✅ | 登录进工作台；`integration_credentials` 加密 token |
| F-WB-NAV-01 | ✅ | 5 项导航可达 |
| F-WB-SIDE-01~04 | ⚠️ | 「未读」替代「高优先级」；计数与列表标签偶发不一致 |
| F-WB-SEARCH-01/02 | ✅ | Ctrl+K / Control+K |
| F-WB-LIST-01/02 | ✅ | mine/pool/all + 7 字段 |
| F-WB-LIST-03 | ⚠️ | seed 阶段标签 OK；飞书 §6 全量待 Sheet |
| F-WB-DETAIL-01 | ⚠️ | 缺合作状态 `status` 展示 |
| F-WB-DETAIL-02/03 | ✅ | 改名 + 阶段校准（`KolStage` JSON 修复） |
| F-WB-DETAIL-04 | ✅ | 打开主页 |
| F-WB-EMAIL-01~04 | ✅ | HTML/折叠/翻译（Moonshot URL 修复） |
| F-WB-SYNC-02 | ✅ | 批量跟进模态框 + 模板 |
| F-BOARD-PIPELINE/RATIO | ✅ | 漏斗/快照切换 |
| F-BOARD-KPI/WINDOW | ⚠️/🚫 | KPI 文案偏差；outreach 窗待飞书 |
| F-TEAM-LIST | ✅/⚠️ | 成员列表 OK；三指标未实现 |
| F-TEAM-OP 分配 | ✅ | pool unassigned+orphaned |
| F-TPL-05 | ✅ | 撰写 + 批量模板 |
| 飞书同步 | ✅ | 个人版 Sheet · ~200 行 · Platform enum 修复后成功 |
| Gmail 历史同步 | ✅ | GCP 启用 Gmail API + 重新 OAuth + 代理；`lauren@lovart.ai` |
| Gmail 增量同步（手动） | ⬜ | 待点「增量同步」验证 |
| Worker 定时同步 | ⬜ | 需启 `maildesk-worker`（见 §九） |
| onboarding 保存跳转 | ✅ | `setQueryData(me)` 修复 |

**下一批优先验**：① 手动增量同步 ② 启 Worker 验 5min Gmail / 30min 飞书 ③ AI 草稿/检查/重新分析 ④ Gmail 单发 ⑤ 定时邮件创建+派发

---

## 九、定时同步如何验证（2026-07-05）

系统里有 **三类「自动/增量」机制**，不要和「历史同步」混为一谈：

| 机制 | 触发方式 | 跑在哪个进程 | 默认频率 | 验证什么 |
|------|----------|--------------|----------|----------|
| **Gmail 历史同步** | 工作台点「历史同步」 | `maildesk-api` | 手动分页 | 近 1 年邮件回填 ✅ 你已验 |
| **Gmail 增量同步（手动）** | 工作台点「增量同步」 | `maildesk-api` | 按需 | 拉 `history.list` 变更 + 2 天 safety net |
| **Gmail 增量同步（定时）** | Worker `@Scheduled` | **`maildesk-worker`** | **每 5 分钟** | 同上，全自动 |
| **飞书 delta 同步（定时）** | Worker `@Scheduled` | **`maildesk-worker`** | **每 30 分钟** | 最多 50 行 upsert（只读） |
| **定时邮件派发** | Worker `@Scheduled` | **`maildesk-worker`** | **每分钟** | `scheduled_emails` → Gmail 发送 |

> **只起 API、不起 Worker = 没有后台定时同步。** 历史/增量按钮走 API；5min/30min/1min 任务必须另启 Worker。

### 9.1 验证手动「增量同步」（5 分钟）

1. 代理/VPN 保持开启  
2. 用 Gmail 网页给某飞书登记达人发一封新邮件（或自己发一封测试）  
3. 工作台点 **「增量同步」**（不是历史）  
4. 期望：提示「处理 N 封」；该达人列表出现新邮件摘要  
5. `/api/v1/me` 的 `lastSyncedAt` 更新（历史同步完成后也会写）

### 9.2 验证 Worker 定时 Gmail 增量（5min）

```bash
# 终端 1：API（已有）
cd kol-mail-desk-v2-backend && set -a && source .env && set +a
mvn -pl maildesk-api spring-boot:run

# 终端 2：Worker（必须另开）
cd kol-mail-desk-v2-backend && set -a && source .env && set +a
mvn -pl maildesk-worker spring-boot:run
```

1. Worker 日志搜：`Gmail incremental sync user=`（约每 5 分钟）  
2. 或临时改 `maildesk.worker.gmail-incremental-sync.cron` 为 `0 */1 * * * *` 加快验证  
3. 发一封新邮件 → 等 1～5 分钟 → 刷新工作台，应自动出现（无需手点）

Worker 健康：`curl -s http://localhost:8081/actuator/health`

### 9.3 验证 Worker 飞书 delta（30min）

- Worker 日志：`Feishu delta sync` / upserted 计数  
- 或在飞书 Sheet 改一行运营名 → 等 30min（或改 cron 加速）→ 再查 DB/UI

### 9.4 验证定时邮件派发（1min）

1. 工作台给某达人写邮件 → **定时发送**（设 3～5 分钟后）  
2. 确认 Worker 在跑  
3. 到点后「定时邮件」页状态变 `sent`；Gmail 已发出

---

## 八、记录模板（后续批次）

```markdown
### 验收批次 YYYY-MM-DD — 验收人：___

| ID | 结果 | 备注 |
|----|------|------|
| F-AUTH-01 | ✅/⚠️/❌ | |
| ... | | |

B 类新发现：
-

Go/No-Go 切流 drill：
```
