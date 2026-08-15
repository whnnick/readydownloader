# Web Deployment

## Production

- Vercel team: `ready-suite`
- Vercel project: `readydownloader`
- Canonical URL: `https://readydownloader.vercel.app`
- Runtime: Node.js 24, Next.js 16, region `sin1`

## Required Resources

Connect one **private** Vercel Blob store to production, preview, and development. The runtime needs `BLOB_READ_WRITE_TOKEN` or the equivalent Vercel OIDC/store configuration. Set `CRON_SECRET` as a sensitive production value so Vercel Cron can authorize `/api/cleanup`.

Optional variables:

- `READYDOWNLOADER_ACCESS_TOKEN`: require a shared access code.
- `READYDOWNLOADER_MAX_OUTPUT_MB`: 25–1000; default 500.
- `READYDOWNLOADER_RETENTION_HOURS`: 1–72; default 24.

Never commit `.env.local`, Blob tokens, OIDC tokens, access codes, or Cron secrets.

## Deploy and Verify

```bash
cd apps/web
npm ci
npm test
npm run check
npm run build
npx vercel deploy --prod --yes --scope ready-suite
```

Verify the canonical URL, `/robots.txt`, `/sitemap.xml`, SSRF rejection, one real supported-page analysis, one real iPhone-compatible download, the signed Blob URL, and final codecs with FFprobe. Delete smoke-test media immediately afterward. A release is incomplete until the matching source, tag, GitHub Release, assets, checksums, GitHub latest, and production Web URL are all verified.
