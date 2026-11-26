// Cloudflare Worker — GET /api/version
// Free plan: 100,000 requests/day, no card needed for Workers.
// Deploy: wrangler deploy api/worker.js --name nextcode-update
// Set the manifest without redeploying:
//   wrangler secret put MANIFEST_JSON   (paste the full manifest JSON)
// Fallback is the embedded template below — replace it before deploying.

const FALLBACK = `{
  "version": "3.0.0",
  "channel": "prod",
  "engine": {
    "url": "https://example.com/nextcode/opencode-cli-3.0.0.exe",
    "sha256": "REPLACE_WITH_SHA256",
    "size": 264423936
  },
  "metadata": { "package": "@opencode/cli" },
  "app": null,
  "notes": "replace before deploying",
  "published_at": "2026-11-25T00:00:00Z"
}`

const headers = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, OPTIONS",
  "cache-control": "no-store",
}

export default {
  fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers })
    if (request.method !== "GET") {
      return new Response(JSON.stringify({ error: "method not allowed" }), { status: 405, headers })
    }
    const url = new URL(request.url)
    if (url.pathname !== "/api/version" && url.pathname !== "/") {
      return new Response(JSON.stringify({ error: "not found" }), { status: 404, headers })
    }
    try {
      const data = JSON.parse(env.MANIFEST_JSON ?? FALLBACK)
      if (!data.version || !data.engine?.url || !/^[a-f0-9]{64}$/i.test(data.engine.sha256 ?? "")) {
        return new Response(JSON.stringify({ error: "manifest is incomplete" }), { status: 500, headers })
      }
      return new Response(JSON.stringify(data), { status: 200, headers })
    } catch (error) {
      return new Response(JSON.stringify({ error: String(error) }), { status: 500, headers })
    }
  },
}
