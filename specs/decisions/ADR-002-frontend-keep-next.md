# ADR-002：前端保留 Next.js

- **状态：** Accepted
- **日期：** 2026-06-27
- **影响范围：** 前端

## 上下文

后端换成 Spring Boot 后，前端有 3 个选项：

1. 保留 Next.js（App Router）
2. 改 Vite SPA
3. Next.js 作 BFF 包装 Spring

## 决定

**保留 Next.js 15 + React 18，作为「带 SSR 的纯前端」，不做 BFF。**

## 理由

### 保留 Next.js 的好处

- **现有组件 100% 复用**：30+ 组件 ~3,584 行可直接迁移
- **RSC + 路由**：六个 SSR 页面（工作台、看板等）只需改数据源
- **登录回调 / SEO / Edge**：Next.js 自带能力，SPA 需要自建
- **复用 Tailwind / TipTap / dompurify 等依赖**：零迁移

### 不改 Vite SPA 的理由

- 需要重写路由、SSR 数据加载、登录回调
- 与现有目录结构差异大，复用率从 70% 降到 50%
- 收益小，仅快约 1 秒首屏，不抵改造成本

### 不做 Next 作 BFF 的理由

- Spring 已是 API，再加一层 BFF 是双层抽象
- BFF 自己需要鉴权、限流、监控，运维负担翻倍
- 仅 RSC 的服务端数据获取就够了，不需要 BFF

## 实施约束

- **没有** Next.js `/api` 路由（删除旧 26 个）
- **没有** 直接 Supabase / Gmail / 飞书调用
- 所有数据走 `lib/api-client/*` → Spring REST
- 认证通过 Spring Security 设置 HttpOnly Cookie

## 影响

- 前端工程师不需要学新框架
- 部署仍可走 Vercel / Static export（取决于是否需要 ISR）
- 视为「Next 是 React 的渲染层 + 路由层」，不再是全栈框架
