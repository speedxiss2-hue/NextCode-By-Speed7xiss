// Vercel serverless function: GET /api/version
// Returns the release manifest. Set MANIFEST_JSON in the environment to override
// the checked-in api/manifest.json without redeploying.
import type { VercelRequest, VercelResponse } from "@vercel/node"
import { readFileSync } from "node:fs"
import { join } from "node:path"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Cache-Control": "no-store",
}

export default function handler(_request: VercelRequest, response: VercelResponse) {
  for (const [key, value] of Object.entries(CORS)) response.setHeader(key, value)
  if (_request.method === "OPTIONS") return response.status(204).end()

  try {
    const raw = process.env.MANIFEST_JSON ?? readFileSync(join(process.cwd(), "api", "manifest.json"), "utf8")
    const manifest = JSON.parse(raw)
    if (!manifest.version || !manifest.engine?.url || !/^[a-f0-9]{64}$/i.test(manifest.engine.sha256 ?? "")) {
      return response.status(500).json({ error: "manifest is missing version, engine.url or a 64-char sha256" })
    }
    return response.status(200).json(manifest)
  } catch (error) {
    return response.status(500).json({ error: error instanceof Error ? error.message : String(error) })
  }
}
