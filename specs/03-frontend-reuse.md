# 前端复用评估

## 一、结论

> **UI 约 70～75% 可复用；整体代码约 40～45% 原样保留。**
>
> 保留：Next.js 框架 + components/ + 领域常量 + AI Prompt + 页面 JSX 骨架。
> 重写：lib/data/、lib/gmail/、lib/feishu/、lib/supabase/、全部 app/api/、认证流程。

## 二、各类别复用度

| 类别 | 文件 / 规模 | 复用度 | 改造方式 |
|------|------------|--------|----------|
| 纯 UI 组件 | `components/*` ~3,584 行 | **85～90%** | 改 fetch 基址与响应类型 |
| 领域常量 | `lib/domain.ts`, `workbench.ts`, `team.ts` ~260 行 | **100%** | 原样保留 |
| AI Prompt | `lib/ai/prompts.ts` ~121 行 | **100%** | 迁到 Spring AI PromptTemplate |
| 模板种子 | `lib/templates/seed-templates.ts` ~99 行 | **100%** | 迁到 DB migration seed |
| SSR 页面 | `app/*/page.tsx` ~1,700 行 | **50～60%** | JSX 保留，`lib/data` → Spring API |
| 认证相关 | `session-bridge`、`google-sign-in`、`auth/*` | **0～10%** | 重写 OAuth 流程 |
| 数据层 | `lib/data/*`, `lib/gmail/*`, `lib/feishu/*`, `lib/supabase/*` | **0%** | 删除，后端承担 |
| Next API Routes | `app/api/*` 26 个 | **0%** | 删除 |

## 三、可直接复用的核心组件清单

以下组件可几乎不改 UI，只换数据来源：

```
WorkbenchShell           工作台三栏布局壳
WorkbenchSearch          顶部搜索（Ctrl+K）
StageFilterBar           阶段筛选条
KolListRow               达人列表行（含 AI 摘要、标签）
EmailBodyViewer          HTML 邮件渲染（含历史折叠）
RichTextEditor           TipTap 富文本编辑器
DraftSendPanel           草稿撰写面板（CC、AI 草稿、定时）
BoardPipelinePanel       看板漏斗 + 阶段分布
TemplateLibrary          模板库
AppShell + AppNav        全局壳 + 导航
GmailSyncButton          Gmail 同步按钮（进度态）
FeishuSyncButton         飞书同步按钮
BatchFollowupButton      批量跟进
KolNameEditor            达人改名
KolStageEditor           阶段校准
ReplyResolvedButton      标记无需回复
MarkEmailReadButton      标记已读
AssignPanel              离职遗留分配
CancelScheduledEmailButton 取消定时邮件
ReclassifyButton         重新分类
DeleteEmailButton        删除邮件
SignOutButton            退出
LovartMark               Logo
```

合计约 30 个组件，~3,584 行。

## 四、必须改造的前端模式

### 4.1 SSR 页面：去掉 `lib/data/*` 直查

**旧模式（去掉）：**

```typescript
// app/page.tsx
const data = await getWorkbenchData({ view, stage, q });
// 内部：Service Role + Supabase 直查 PostgREST
```

**新模式：**

```typescript
// app/page.tsx
const data = await apiClient.workbench.get(
  { view, stage, q },
  { cookies }
);
// 走 Spring REST /api/v1/workbench
```

### 4.2 Client 组件：fetch 路径切到 `/api/v1`

旧组件中大部分已经在 fetch `/api/...`，只需改基址与响应类型。

**改造前：**

```typescript
fetch('/api/kols/' + kolId, { method: 'PATCH', body: JSON.stringify(...) })
```

**改造后：**

```typescript
import { apiClient } from '@/lib/api-client';
apiClient.kols.update(kolId, { name, stage, replyResolved });
```

### 4.3 认证：删 Supabase，使用 Spring Cookie

旧：`session-bridge.tsx` 把 Supabase session 写入 cookie。

新：浏览器跳转 `/oauth2/authorization/google`（Spring Security 自带端点）→ 回调由后端设置 HttpOnly Cookie。前端只需读取 `/api/v1/me` 获取用户信息。

### 4.4 `app/api/*` 全删

旧的 26 个 Next API Routes 全部废弃。前端不再有任何 API Route。

## 五、新增前端目录

```
lib/
├── api-client/
│   ├── index.ts              # 客户端工厂、错误处理
│   ├── auth.ts               # /api/v1/auth/*
│   ├── workbench.ts          # /api/v1/workbench
│   ├── kols.ts               # /api/v1/kols/*
│   ├── emails.ts             # /api/v1/emails/*
│   ├── board.ts              # /api/v1/board
│   ├── team.ts               # /api/v1/team/*
│   ├── templates.ts          # /api/v1/templates/*
│   ├── scheduled.ts          # /api/v1/scheduled-emails/*
│   ├── sync.ts               # /api/v1/sync/*
│   ├── gmail.ts              # /api/v1/gmail/*
│   ├── ai.ts                 # /api/v1/ai/*
│   └── types.ts              # 由 OpenAPI 生成
├── domain.ts                 # 保留（旧 lib/domain.ts）
├── workbench.ts              # 保留（旧 lib/workbench.ts）
└── team.ts                   # 保留（旧 lib/team.ts）
```

类型生成：

```bash
# 在 Phase 1 配置
npx openapi-typescript ../kol-mail-desk-v2-docs/specs/api-contract-v1.yaml \
  -o lib/api-client/types.ts
```

## 六、是否继续用 Next.js？

**建议：继续用 Next.js，但 SSR 改走 API。**

| 选项 | 建议 | 理由 |
|------|------|------|
| 保留 Next.js（App Router） | ✅ | 复用 RSC、路由、Tailwind、现有页面 |
| 改 Vite SPA | ❌ | 需重写路由/SSR，收益小 |
| Next 作 BFF | ⚠️ | 首版不必；Spring 已是 API，避免双 BFF |

## 七、工作量估算

| 工作项 | 人天 |
|--------|------|
| api-client + 类型定义 | 5～8 |
| 6 个 SSR 页面改数据源 | 8～12 |
| 认证 / OAuth 重写 | 5～8 |
| 20+ Client 组件改 endpoint | 3～5 |
| 联调 + E2E | 10～15 |
| **合计** | **约 31～48 人天（1 个前端 6～10 周）** |

## 八、UI 验收注意点（v3.3 不可丢的体验）

| 体验 | 不变 |
|------|------|
| HTML 邮件渲染 + 图片 + 链接 + 历史折叠 | EmailBodyViewer |
| 富文本：粗体/斜体/下划线/颜色/有序无序列表/链接 | RichTextEditor |
| CC 编辑、HTML 发送（multipart/alternative） | DraftSendPanel |
| `Ctrl+K` 聚焦搜索 | WorkbenchSearch |
| 工作台三栏（左导航 + 中工作台 + 右达人/邮件） | WorkbenchShell |
| 同步按钮非阻塞（边同步边操作） | GmailSyncButton |
| 顶栏「重新授权 Gmail」按钮在 Token 过期时出现 | 按钮态 |
| 看板「累计漏斗」与「阶段分布」两种模式切换 | BoardPipelinePanel |
| 飞书状态映射后中文标签一致 | domain.ts STAGE_LABEL |

## 九、不可复用、需要重写的代码

| 文件 | 行数 | 原因 |
|------|------|------|
| `lib/data/workbench-data.ts` | 459 | Supabase 直查 + 缓存标签 |
| `lib/data/board-data.ts` | 405 | 同上 |
| `lib/data/team-data.ts` | 140 | 同上 |
| `lib/data/template-data.ts` | 93 | 同上 |
| `lib/data/scheduled-email-data.ts` | 68 | 同上 |
| `lib/data/assign-data.ts` | 116 | 同上 |
| `lib/gmail/sync.ts` | 263 | Java 重写 |
| `lib/gmail/persist.ts` | 275 | Java 重写 |
| `lib/gmail/send.ts`, `send-pipeline.ts`, `parser.ts`, `process-scheduled.ts`, `run-sync.ts` | ~818 | Java 重写 |
| `lib/feishu/sync-kols.ts` | 648 | Java 重写 |
| `lib/ai/client.ts` | 279 | 部分迁移：prompts 保留，client 改 Spring AI |
| `lib/supabase/*` | 125 | 删除 |
| `lib/audit.ts` | 50 | Java 重写（写 actions 表） |
| `app/api/*` 26 个 | ~1,573 | 删除 |
| 合计 | ~5,200 行 | — |

## 十、迁移策略

### Phase 1（只读核心）

1. `npx create-next-app` 新项目
2. 从旧仓库 copy：`components/`、`lib/domain.ts`、`lib/workbench.ts`、`lib/team.ts`、`tailwind.config.ts`、`postcss.config.js`、`app/globals.css`
3. **删除** copy 来的 `lib/supabase/*`、`lib/data/*`、`lib/gmail/*`、`lib/feishu/*`、`app/api/*`
4. 添加 `lib/api-client/` 与一个 mock server（Mockoon 或 Spring 空实现）
5. 改造 `app/page.tsx` 等 6 个 SSR 页面接 api-client
6. 改造 client 组件 fetch 路径

### Phase 2～6

跟随后端 API 增量上线，逐功能联调。

## 十一、特别注意：TipTap、isomorphic-dompurify、marked

| 库 | 用途 | 处理 |
|------|------|------|
| `@tiptap/react` + 扩展 | 富文本编辑 | 保留 |
| `isomorphic-dompurify` | 净化 HTML 邮件 | 保留 |
| `marked` | Markdown 渲染（AI 草稿） | 保留 |
| `lucide-react` | 图标 | 保留 |
| `zod` | 客户端校验 | 保留（轻量） |

## 十二、不要做的事

- ❌ 不要在 Next.js `/api` 路由里再写业务逻辑
- ❌ 不要在前端引入 `@supabase/*`
- ❌ 不要在前端直接调 Gmail / 飞书 / Kimi
- ❌ 不要在 Client Component 里持有 OAuth Token
- ❌ 不要复制 `lib/audit.ts`（审计在后端写）
