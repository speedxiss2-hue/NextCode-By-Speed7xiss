// Render / generic Node host: serves GET /api/version and GET /health on PORT.
// Set MANIFEST_JSON to override the checked-in manifest without redeploying.
const http = require("node:http")
const fs = require("node:fs")
const path = require("node:path")

const header = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, OPTIONS",
  "access-control-allow-headers": "Content-Type",
  "cache-control": "no-store",
}

function manifest() {
  const raw = process.env.MANIFEST_JSON ?? fs.readFileSync(path.join(__dirname, "manifest.json"), "utf8")
  const data = JSON.parse(raw)
  if (!data.version || !data.engine?.url || !/^[a-f0-9]{64}$/i.test(data.engine.sha256 ?? ""))
    throw new Error("manifest is missing version, engine.url or a 64-char sha256")
  return data
}

http
  .createServer((request, response) => {
    if (request.method === "OPTIONS") {
      response.writeHead(204, header)
      return response.end()
    }
    if (request.method !== "GET") {
      response.writeHead(405, header)
      return response.end(JSON.stringify({ error: "method not allowed" }))
    }
    if (request.url === "/health") {
      response.writeHead(200, header)
      return response.end(JSON.stringify({ ok: true }))
    }
    if (request.url !== "/api/version") {
      response.writeHead(404, header)
      return response.end(JSON.stringify({ error: "not found" }))
    }
    try {
      response.writeHead(200, header)
      response.end(JSON.stringify(manifest()))
    } catch (error) {
      response.writeHead(500, header)
      response.end(JSON.stringify({ error: error.message }))
    }
  })
  .listen(Number(process.env.PORT ?? 3000), "0.0.0.0", () => {
    console.log(`NextCode update API on ${process.env.PORT ?? 3000}`)
  })
