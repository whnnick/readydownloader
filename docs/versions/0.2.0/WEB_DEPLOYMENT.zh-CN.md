# Web 部署指南

## 生产环境

- Vercel 团队：`ready-suite`
- Vercel 项目：`readydownloader`
- 规范地址：`https://readydownloader.vercel.app`
- 运行时：Node.js 24、Next.js 16、`sin1` 区域

## 必需资源

将一个**私有** Vercel Blob 同时连接到 production、preview 和 development。运行时需要 `BLOB_READ_WRITE_TOKEN` 或等价的 Vercel OIDC/Store 配置。将 `CRON_SECRET` 设置为生产敏感变量，以便 Vercel Cron 授权 `/api/cleanup`。

可选变量：

- `READYDOWNLOADER_ACCESS_TOKEN`：要求共享访问码。
- `READYDOWNLOADER_MAX_OUTPUT_MB`：25–1000，默认 500。
- `READYDOWNLOADER_RETENTION_HOURS`：1–72，默认 24。

严禁提交 `.env.local`、Blob Token、OIDC Token、访问码或 Cron Secret。

## 部署与验证

```bash
cd apps/web
npm ci
npm test
npm run check
npm run build
npx vercel deploy --prod --yes --scope ready-suite
```

必须验证规范域名、`/robots.txt`、`/sitemap.xml`、SSRF 拒绝、一个真实受支持页面的解析、一次真实 iPhone 兼容下载、签名 Blob 链接，以及 FFprobe 最终编码，并立即删除冒烟测试媒体。只有对应源码、Tag、GitHub Release、产物、校验和、GitHub latest 和 Web 生产地址全部完成验证，版本发布才算完成。
