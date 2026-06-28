# 本地开发环境搭建

> 目标：任何新人 / 新窗口在 **1 小时内** 把后端 + 前端 + 数据库 + Redis 跑起来，能登录、能调一个 API、能跑测试。

---

## 1. 工具版本要求

| 工具 | 版本 | 验证命令 |
|------|------|---------|
| JDK | 21（Temurin / Zulu / GraalVM CE 均可） | `java -version` |
| Maven | 3.9+ | `mvn -v` |
| Node.js | 20 LTS（≥ 20.10） | `node -v` |
| pnpm / npm | pnpm 9+ 或 npm 10+ | `pnpm -v` / `npm -v` |
| Docker | Desktop 4.30+ 或 Engine 24+ | `docker --version` |
| Docker Compose | v2.20+（Docker Desktop 自带） | `docker compose version` |
| Git | 2.39+ | `git --version` |

> macOS 推荐用 [SDKMAN](https://sdkman.io/) 管理 JDK / Maven，[nvm](https://github.com/nvm-sh/nvm) 管理 Node。

---

## 2. 仓库克隆

三个仓库放在 `~/code/` 下，互为兄弟目录（路径关系被 `AGENTS.md` 引用）：

```bash
mkdir -p ~/code && cd ~/code

# 旧仓库（只读参考，禁止修改）
git clone https://github.com/tianhhe/kol-mail-desk.git

# 新仓库（待团队推到远端后替换 URL）
git clone <docs-repo-url>     kol-mail-desk-v2-docs
git clone <backend-repo-url>  kol-mail-desk-v2-backend
git clone <web-repo-url>      kol-mail-desk-v2-web
```

目录结构应为：

```
~/code/
├── kol-mail-desk/                       # 旧仓库（只读）
├── kol-mail-desk-v2-docs/
├── kol-mail-desk-v2-backend/
├── kol-mail-desk-v2-web/
└── maildesk-v2.code-workspace           # Cursor multi-root workspace 入口
```

---

## 2.5 用 Multi-root Workspace 打开（推荐）

本项目采用**单 Cursor 窗口 + multi-root workspace** 模式，一次会话能同时改前后端 + OpenAPI 契约，避免两个窗口工作时契约漂移。

### 打开方式

```bash
# macOS
cursor ~/code/maildesk-v2.code-workspace
```

或 Cursor 内 `File → Open Workspace from File...` 选 `maildesk-v2.code-workspace`。

打开后侧边栏会同时显示 4 个 root：

```
📘 docs       — specs / STATUS / BACKLOG / OpenAPI 契约
⚙️ backend    — Spring Boot + MyBatis-Plus
🖥️ web        — Next.js
📦 legacy     — 旧仓库（只读参考）
```

### Cursor Rules 行为

| Root | `.cursor/rules/` | 加载条件 |
|------|------------------|---------|
| docs | 无 | — |
| backend | `00-global.mdc` / `backend-java.mdc` | 编辑 `.java` 文件时 backend-java 激活 |
| web | `00-global.mdc` / `frontend-next.mdc` | 编辑 `.ts/.tsx` 文件时 frontend-next 激活 |
| legacy | 无 | — |

两个 `00-global.mdc` 都是 `alwaysApply: true`，规则会同时加载（约定一致，无冲突）。

### 工作流示例（单次会话完成一个垂直切片）

1. 改 `📘 docs/specs/api-contract-v1.yaml`（先写契约）
2. 改 `⚙️ backend/maildesk-api/.../controller/XxxController.java`（实现接口）
3. 改 `⚙️ backend/maildesk-application/.../service/XxxApplicationService.java`（业务逻辑）
4. 在 `🖥️ web` 跑 `pnpm gen:api`（从最新契约重生成 TS 类型）
5. 改 `🖥️ web/app/.../page.tsx` + `🖥️ web/components/...`（前端调用）
6. 写 E2E case
7. 一次性更新 `📘 docs/specs/STATUS.md` + `BACKLOG.md` + `05-feature-parity.md`
8. 三个仓库各自 commit（同一份变更说明）

### 为什么不直接打开单个 repo 的窗口

- 单 repo 窗口看不到 OpenAPI 契约 / STATUS，Agent 容易自作主张
- 前后端独立窗口最容易出现的问题是「字段名 / 错误码 / 业务语义对不上」
- multi-root 模式下 Agent 一次会话能看完整上下文，主动校对契约

---

## 3. 外部账号清单

下表的账号 / Key **必须先准备好**，否则部分功能跑不起来。

| 账号 | 用途 | 阻塞的 Phase | 申请负责人 | 状态 |
|------|------|------------|-----------|------|
| Google Cloud Console 项目 | OAuth Client + Gmail API | P1 起 | _待指定_ | ⬜ |
| Google OAuth Client ID/Secret | 登录 + Gmail 授权 | P1 起 | _待指定_ | ⬜ |
| Google OAuth 测试用户名单 | 未发布到生产前需在白名单 | P1 起 | _待指定_ | ⬜ |
| 飞书开放平台应用 | 读取 KOL 表 | P2 起 | _待指定_ | ⬜ |
| 飞书 App ID + App Secret | 飞书 API 鉴权 | P2 起 | _待指定_ | ⬜ |
| 飞书 KOL 多维表格 ID + Table ID | 同步源 | P2 起 | _待指定_ | ⬜ |
| Kimi / Moonshot API Key | AI 分类 / 草稿 / 翻译 | P4 起 | _待指定_ | ⬜ |
| AWS 账号（或同等云） | S3、Secrets Manager、RDS | P6 起 | _待指定_ | ⬜ |
| 域名 + SSL | 生产环境 | P6 起 | _待指定_ | ⬜ |
| Stripe（可选） | SaaS 计费 | P7 | _待指定_ | ⬜ |

> 各 Key 申请教程：见旧仓库 README 与 Google / 飞书 / Moonshot 各自的官方文档。`docs/onboarding/` 下后续会补 step-by-step 截图（Phase 0 末期完成）。

---

## 4. 环境变量

### 4.1 后端 `.env`（`kol-mail-desk-v2-backend/.env`）

> 该文件 **不要提交**（已在 `.gitignore`）。仓库根放 `.env.example` 作为模板。

```bash
# ===== 基础 =====
SPRING_PROFILES_ACTIVE=dev
SERVER_PORT=8080

# ===== 数据库 =====
DB_HOST=localhost
DB_PORT=5432
DB_NAME=maildesk
DB_USER=maildesk
DB_PASSWORD=maildesk_local

# ===== Redis =====
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# ===== Google OAuth =====
GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:8080/api/v1/auth/google/callback
GOOGLE_GMAIL_SCOPES=https://www.googleapis.com/auth/gmail.readonly,https://www.googleapis.com/auth/gmail.send

# ===== 飞书 =====
FEISHU_APP_ID=
FEISHU_APP_SECRET=
FEISHU_KOL_APP_TOKEN=
FEISHU_KOL_TABLE_ID=

# ===== AI / Kimi =====
KIMI_API_KEY=
KIMI_BASE_URL=https://api.moonshot.cn/v1
KIMI_MODEL_SMALL=moonshot-v1-8k
KIMI_MODEL_LARGE=moonshot-v1-128k

# ===== 加密（AES-256 主密钥，base64 编码 32 字节） =====
TOKEN_ENCRYPTION_KEY=

# ===== 多租户（开发期固定值） =====
DEFAULT_TENANT_ID=00000000-0000-0000-0000-000000000001

# ===== 前端 CORS =====
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

生成 `TOKEN_ENCRYPTION_KEY`：

```bash
openssl rand -base64 32
```

### 4.2 前端 `.env.local`（`kol-mail-desk-v2-web/.env.local`）

```bash
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
NEXT_PUBLIC_APP_NAME=Lovart Mail Desk
```

---

## 5. 启动依赖中间件（PG + Redis）

仓库根 `docker-compose.dev.yml` 会在 P0-T11 补上，最终内容大致为：

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: maildesk
      POSTGRES_USER: maildesk
      POSTGRES_PASSWORD: maildesk_local
    ports:
      - "5432:5432"
    volumes:
      - maildesk_pg:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - maildesk_redis:/data
volumes:
  maildesk_pg:
  maildesk_redis:
```

启动：

```bash
cd ~/code/kol-mail-desk-v2-backend
docker compose -f docker-compose.dev.yml up -d
docker compose -f docker-compose.dev.yml ps    # 验证两个容器 healthy
```

停止：`docker compose -f docker-compose.dev.yml down`（保留卷）。
彻底清空：`docker compose -f docker-compose.dev.yml down -v`。

---

## 6. 后端首跑

```bash
cd ~/code/kol-mail-desk-v2-backend

# 1. 加载环境变量
set -a; source .env; set +a

# 2. 构建（首次会下载依赖，约 3～5 分钟）
mvn -B clean install -DskipTests

# 3. Flyway 自动迁移（API 启动时执行）+ 启动 API
mvn -B -pl maildesk-api spring-boot:run

# 另开 terminal 启动 Worker
set -a; source .env; set +a
mvn -B -pl maildesk-worker spring-boot:run
```

健康检查：

```bash
curl -s http://localhost:8080/actuator/health
# 期望：{"status":"UP",...}

curl -s http://localhost:8080/api/v1/health
# 期望：{"code":0,"data":"OK"}
```

OpenAPI / Swagger UI：

```
http://localhost:8080/swagger-ui/index.html
```

---

## 7. 前端首跑

```bash
cd ~/code/kol-mail-desk-v2-web

# 1. 安装依赖
pnpm install        # 或 npm install

# 2. 从后端拉 OpenAPI 生成 TS 类型（Phase 1 起会自动跑）
pnpm run gen:api    # 占位脚本，Phase 1 接入 openapi-typescript

# 3. 启动 dev server
pnpm dev
```

访问 `http://localhost:3000`。登录走 Google OAuth，回调地址必须在 Google Console 配置过。

---

## 8. 跑测试

```bash
cd ~/code/kol-mail-desk-v2-backend

# 单元测试（不依赖外部）
mvn -B test

# 集成测试（依赖 Testcontainers，会拉起临时 PG + Redis）
mvn -B verify -Pintegration

# 单模块测试
mvn -B -pl maildesk-application -am test

# ArchUnit 守护测试
mvn -B -pl maildesk-domain test -Dtest=*ArchitectureTest
```

前端：

```bash
cd ~/code/kol-mail-desk-v2-web
pnpm test            # vitest
pnpm test:e2e        # playwright（需先启动后端 + 前端）
```

---

## 9. 造测试数据

`maildesk-infrastructure/src/main/resources/db/seed/`（Phase 1 末期补）会提供：

- `dev-tenant.sql`：1 个 dev 租户
- `dev-users.sql`：1 leader + 2 member + 1 intern
- `dev-kols.sql`：~30 个测试达人，覆盖所有 10 个阶段
- `dev-emails.sql`：~100 封 inbound + outbound 邮件
- `dev-templates.sql`：5 个示例模板

加载方式：

```bash
psql postgresql://maildesk:maildesk_local@localhost:5432/maildesk \
  -f maildesk-infrastructure/src/main/resources/db/seed/dev-tenant.sql
# ...其他 seed 文件
```

或：

```bash
mvn -B -pl maildesk-worker spring-boot:run -Dspring.profiles.active=dev,seed
```

---

## 10. 旧仓库本地参考（只读）

旧仓库 `~/code/kol-mail-desk`：

- **只读，禁止 commit 修改**
- Agent 不允许写入；本地手动改也只用作"看实现细节"
- 启动方式（如果需要对比行为）：

  ```bash
  cd ~/code/kol-mail-desk
  npm install
  cp .env.local.example .env.local   # 填 Supabase / Google / 飞书 / Kimi 测试 Key
  npm run dev
  ```

  > 旧仓库 `.env.local` 与新仓库 `.env` **绝不混用**，避免误把开发数据写到旧 Supabase。

---

## 11. 常见错误排查

| 现象 | 原因 | 排查 |
|------|------|------|
| `mvn` 启动失败：`Connection refused: localhost:5432` | docker-compose 没起 | `docker compose ps`，看 postgres 是否 healthy |
| `Flyway: validate failed` | 本地 schema 与 migration 不一致 | `docker compose down -v` 后重启重建 |
| 后端启动报 `TOKEN_ENCRYPTION_KEY must be 32 bytes` | 主密钥未设置或长度不对 | `openssl rand -base64 32` 重生成 |
| Google OAuth 回调 400 | redirect_uri 不在 GCP 白名单 | Console → OAuth client → Authorized redirect URIs |
| Gmail API 403 `accessNotConfigured` | GCP 项目未启用 Gmail API | Console → APIs → Enable Gmail API |
| 飞书 sync 99991663 | App Secret 不对或应用未发布 | 飞书开放平台 → 应用版本 → 发布 |
| Kimi 401 | API Key 不对 | https://platform.moonshot.cn/console/api-keys |
| Kimi 余额不足 | 充值 | 系统应"AI 失败入库不阻塞"，验证降级逻辑 |
| 前端 401 / CORS | 后端 CORS / cookie 配置 | 检查 `CORS_ALLOWED_ORIGINS` 包含 `http://localhost:3000` |
| `pnpm dev` 失败 `EACCES` | Node permission | 用 nvm 重装 Node，不要全局 sudo |

---

## 12. 开发期推荐 IDE 设置

### IntelliJ IDEA

- Project SDK：21
- 启用 Lombok 插件
- 启用 Annotation Processing（`Settings → Build → Compiler → Annotation Processors`）
- 启用 Maven auto-import
- 推荐插件：Spring Boot Assistant、MyBatisX、Save Actions、CheckStyle

### VS Code / Cursor

- Java：Extension Pack for Java
- Spring Boot Tools
- MyBatis-Plus（搜索 mapper 用）
- ESLint + Prettier（前端）

---

## 13. SETUP 文件的演化协议

- 本文件 placeholder（外部账号责任人、`docker-compose.dev.yml` 实际内容、seed 文件清单等）由对应 ticket 完成时回填
- **凡是被 README / AGENTS / specs 引用到的本地启动步骤**，必须在本文件有对应章节
- 启动命令变更（如 Maven goal 改变、新增中间件）必须同步更新本文件 + STATUS 标记
