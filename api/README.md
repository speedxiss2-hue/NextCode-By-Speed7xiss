# NextCode update API

One endpoint: `GET /api/version`. The client (`autoupdate.ps1`, `update.ts`, and
the patched CLI updater) reads it before downloading anything.

## Manifest shape

```json
{
  "version": "3.0.1",
  "channel": "prod",
  "engine": {
    "url": "https://your-cdn.example/opencode-cli-3.0.1.exe",
    "sha256": "64 lowercase hex characters",
    "size": 264423936
  },
  "metadata": { "package": "@opencode/cli" },
  "app": null,
  "notes": "what changed",
  "published_at": "2026-11-25T00:00:00Z"
}
```

`metadata.package` keeps the stock CLI updater parser happy. `app` is optional;
when present with `url` and `sha256`, `install.ps1 -Bundle` can swap the whole
desktop package instead of just the engine.

## Host on Vercel

1. Import this folder as a Vercel project (framework: Other).
2. Deploy. `api/version.ts` serves `GET /api/version`.
3. To publish a release without redeploying, set the `MANIFEST_JSON` environment
   variable to the full manifest JSON. Redeploy is then unnecessary.
4. Point clients at `https://<your-project>.vercel.app`.

## Cheapest option: static hosting (no server at all)

The manifest is a JSON file, so a server is optional. `api/version` is a copy of
`manifest.json` with no extension — upload the `api/` folder to GitHub Pages,
Cloudflare Pages, Netlify or jsDelivr and point clients at
`https://<site>/api/version`. Keep `api/version` in sync with `api/manifest.json`
when you publish a release. Clients also accept a direct `*.json` URL, so a raw
`manifest.json` link works too.

Recommended free picks:

| Host | Free tier | Shape |
|---|---|---|
| GitHub Pages / Cloudflare Pages | free | static `api/version` |
| Cloudflare Workers | 100,000 requests/day | `api/worker.js` |
| Vercel Hobby | free | `api/version.ts` |
| Netlify | free | static or function |
| Deno Deploy | free | Worker-style handler |
| Fly.io Free | $0/mo, tight limits (3 machines, 1 user) | `api/server.js` in a container |
| Render free | free web service (spins down) | `api/server.js` |

Fly.io does have a Free plan again, but it is small and may ask for a card at
signup. Cloudflare Workers is the safest free dynamic choice; static Pages is
the simplest and has no request worries.

## Cloudflare Worker

```powershell
wrangler deploy api/worker.js --name nextcode-update
wrangler secret put MANIFEST_JSON    # paste the manifest JSON
```

Endpoint: `https://nextcode-update.<account>.workers.dev/api/version`.

## Host on Render

1. New Web Service, runtime Node, build command `npm install`, start command
   `node api/server.js`.
2. Set `PORT` (Render provides it) and optionally `MANIFEST_JSON`.
3. Point clients at `https://<your-service>.onrender.com`.

## Publishing a release

1. Upload the new `opencode-cli.exe` to your CDN/object storage.
2. Compute its hash: `Get-FileHash engine.exe -Algorithm SHA256`.
3. Update `api/manifest.json` (or `MANIFEST_JSON`) with version, URL and hash.
4. Users run `autoupdate.bat -Check`, then `autoupdate.bat`.
   The script verifies SHA-256, stages the download, keeps a rollback copy in
   `backup\` and writes `backup\autoupdate.log`.

## Verify locally

```powershell
$env:MANIFEST_JSON = Get-Content -Raw api\manifest.json
node api\server.js
curl http://127.0.0.1:3000/api/version
```
