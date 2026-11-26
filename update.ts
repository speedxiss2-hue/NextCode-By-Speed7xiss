// Keeps NextCode current. Prefers a manifest served by your own API (Vercel/Render),
// falls back to the upstream npm feed. Verifies SHA-256 before touching the engine.
// Usage:
//   bun update.ts              update now if a newer release exists
//   bun update.ts --check      report only, change nothing
//   bun update.ts --if-due     update only when the last check is older than DUE_HOURS
//   bun update.ts --quiet      no console output unless something changed
//
// Set NEXTCODE_UPDATE_API or write update-api.txt next to this file to point at the
// manifest host. The endpoint must answer GET /api/version with:
//   { version, engine: { url, sha256 } }

import { $ } from "bun"
import { createHash } from "node:crypto"
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs"
import { join } from "node:path"

const root = import.meta.dir
const build = join(root, "build")
const resources = join(build, "resources")
const engine = join(resources, "opencode-cli.exe")
const versionFile = join(resources, "opencode-cli.version")
const stamp = join(root, "backup", ".last-update-check")
const backup = join(root, "backup")
const apiFile = join(root, "update-api.txt")
const DUE_HOURS = 6
const FEED = "https://opencode.ai/update/api/latest/cli/npm"

const flags = new Set(process.argv.slice(2))
const quiet = flags.has("--quiet")
const check = flags.has("--check")
const ifDue = flags.has("--if-due")

const log = (message: string) => {
  if (!quiet) console.log(message)
}

type Release = {
  version: string
  package: string
  url?: string
  sha256?: string
}

function apiBase() {
  const configured = process.env.NEXTCODE_UPDATE_API ?? (existsSync(apiFile) ? readFileSync(apiFile, "utf8").trim() : "")
  return configured ? configured.replace(/\/$/, "") : ""
}

async function fetchWithRetry(url: string, timeout: number, attempts = 3) {
  let last = ""
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(timeout) })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      return response
    } catch (error) {
      last = error instanceof Error ? error.message : String(error)
      if (attempt < attempts) await Bun.sleep(2_000 * attempt)
    }
  }
  throw new Error(`cannot reach ${url} after ${attempts} attempts: ${last}`)
}

function sha256(data: Uint8Array) {
  return createHash("sha256").update(data).digest("hex")
}

async function fromApi(base: string): Promise<Release> {
  const response = await fetchWithRetry(base.endsWith(".json") ? base : `${base}/api/version`, 20_000)
  const manifest = await response.json() as {
    version?: string
    engine?: { url?: string; sha256?: string }
  }
  if (!manifest.version) throw new Error("manifest has no version")
  if (!manifest.engine?.url) throw new Error("manifest has no engine.url")
  if (!manifest.engine.sha256 || !/^[a-f0-9]{64}$/i.test(manifest.engine.sha256))
    throw new Error("manifest engine.sha256 is not a 64-char hex string")
  return {
    version: manifest.version,
    package: "@opencode/cli",
    url: manifest.engine.url,
    sha256: manifest.engine.sha256.toLowerCase(),
  }
}

async function fromFeed(): Promise<Release> {
  const response = await fetchWithRetry(FEED, 20_000)
  const data = await response.json() as { version?: string; metadata?: { package?: string } }
  if (!data.version) throw new Error("release feed returned no version")
  return { version: data.version, package: data.metadata?.package ?? "@opencode/cli" }
}

function currentVersion() {
  try {
    return readFileSync(versionFile, "utf8").trim()
  } catch {
    return ""
  }
}

function semver(input: string) {
  const match = input.trim().match(/^v?(\d+)\.(\d+)\.(\d+)/)
  if (!match) return
  return [Number(match[1]), Number(match[2]), Number(match[3])] as const
}

function isNewer(candidate: string, existing: string) {
  const next = semver(candidate)
  const prev = semver(existing)
  if (!next) return false
  if (!prev) return true
  for (let index = 0; index < 3; index++) {
    if (next[index] !== prev[index]) return next[index] > prev[index]
  }
  return false
}

function due() {
  if (!ifDue) return true
  try {
    const wrote = readFileSync(stamp, "utf8").trim()
    const age = Date.now() - Date.parse(wrote)
    return !Number.isFinite(age) || age > DUE_HOURS * 60 * 60 * 1000
  } catch {
    return true
  }
}

function markChecked() {
  mkdirSync(backup, { recursive: true })
  writeFileSync(stamp, new Date().toISOString())
}

function pruneBackups() {
  const kept = readdirSync(backup)
    .filter((name) => /^opencode-cli-.+\.exe$/.test(name))
    .map((name) => ({ name, at: statSync(join(backup, name)).mtimeMs }))
    .sort((a, b) => b.at - a.at)
    .slice(2)
  kept.forEach((entry) => rmSync(join(backup, entry.name), { force: true }))
}

if (!existsSync(engine)) {
  console.error(`No engine at ${engine}. Run build.bat first.`)
  process.exit(1)
}

if (!due()) process.exit(0)

const installed = currentVersion()
let release: Release
const base = apiBase()
try {
  release = base ? await fromApi(base) : await fromFeed()
} catch (error) {
  log(`update check skipped: ${error instanceof Error ? error.message : String(error)}`)
  process.exit(0)
}

if (installed === release.version) {
  markChecked()
  log(`NextCode engine ${installed} is current`)
  process.exit(0)
}

if (!isNewer(release.version, installed)) {
  markChecked()
  log(`NextCode engine ${installed} is newer than the available release (${release.version}); nothing to do`)
  process.exit(0)
}

log(`NextCode engine ${installed || "unknown"} -> ${release.version}`)
if (check) {
  console.log(`update available: ${release.version}`)
  process.exit(0)
}

const staging = join(backup, `cli-${release.version}`)
rmSync(staging, { recursive: true, force: true })
mkdirSync(staging, { recursive: true })

let downloaded = join(staging, "opencode.exe")
if (release.url && release.sha256) {
  log(`downloading ${release.url}`)
  const response = await fetchWithRetry(release.url, 600_000)
  const bytes = new Uint8Array(await response.arrayBuffer())
  const actual = sha256(bytes)
  if (actual !== release.sha256) {
    console.error(`sha256 mismatch: got ${actual}, expected ${release.sha256}`)
    process.exit(1)
  }
  writeFileSync(downloaded, bytes)
} else {
  log(`downloading ${release.package}@${release.version}`)
  const result = await $`npm install ${release.package}@${release.version} --prefix ${staging} --no-save --no-audit --no-fund --loglevel=error`.quiet()
  if (result.exitCode !== 0) {
    console.error(result.stderr.toString().trim() || `npm exited with ${result.exitCode}`)
    process.exit(1)
  }
  downloaded = join(staging, "node_modules", "@opencode", "cli", "bin", "opencode.exe")
  if (!existsSync(downloaded)) {
    console.error(`the ${release.package} package did not contain bin/opencode.exe`)
    process.exit(1)
  }
}

const probe = await $`${downloaded} --version`.quiet()
const reported = probe.stdout.toString().trim()
if (!reported.includes(release.version)) {
  console.error(`the downloaded engine reports "${reported}", expected ${release.version}`)
  process.exit(1)
}

if (installed) {
  mkdirSync(backup, { recursive: true })
  copyFileSync(engine, join(backup, `opencode-cli-${installed}.exe`))
  pruneBackups()
}

copyFileSync(downloaded, engine)
writeFileSync(versionFile, release.version)
rmSync(staging, { recursive: true, force: true })
markChecked()

log(`engine updated to ${release.version}. Relaunch NextCode to use it.`)
