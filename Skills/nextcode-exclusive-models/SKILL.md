---
name: nextcode-exclusive-models
description: NextCode's exclusive opencode/* model roster — unlimited cloud inference, vision, and universal file reading. Load for model choice, image/PDF/source analysis, and fallback routing. Never routes to Ollama.
---

# NextCode exclusive models — the only brain

Ollama and other local runtimes are not used. The brain is the NextCode-only
free roster exposed by the fork:

```
opencode/nemotron-3.5-super-vl-free   <- default: vision + code
opencode/hy4-flash-free               <- fast fallback
opencode/big-pickle
opencode/iceman-free
opencode/beam-free
opencode/deepseek-v4.1-flash-free
opencode/flint-40b-free
opencode/mimo-v2.6-flash-free
opencode/nemotron-3.5-lightning-free
opencode/tidepool-alpha-free
```

Run `opencode models` to refresh the roster — it changes as the feed updates.

## Infinite usage

These are cloud models with no per-token bill on this fork. When the free limit
appears, use the NextCode desktop **reset usage** button. The bundled WARP local
proxy rotates the exit IP; the reset console retries and falls back to Tor when
Cloudflare rate-limits. No local model, no API key, no quota to buy.

If a model call fails: switch to the next `opencode/*` model and say which one.
Never fall back to a local runtime.

## Vision and file reading

- Images: pass the absolute path to the `read` tool, or use the `vision` subagent.
  `opencode/nemotron-3.5-super-vl-free` handles image input. Report only what is
  legible — never invent labels or text.
- PDF: `read` handles PDFs. For long files use `pdftotext -layout` or Python
  `pypdf`, then cite the page.
- cpp/hpp/c/java/js/jsx/ts/tsx/py/go/rs/cs: plain text — `read` directly; use
  `glob`/`grep` to locate symbols in large trees first.
- docx/xlsx/pptx: python-docx / openpyxl / python-pptx.
- logs: filter by level/timestamp before reading.
- archives/binaries: list with `7z l` / `tar -tf`; `strings`, `file`, hex dump.

## Memory ledger

Keep `C:\Users\Usuario\.config\opencode\session_memory.json` as a factual ledger:
request, tools run, paths touched, results, open items. Never claim a file was
not created without checking the ledger and disk. Compress old context into the
ledger instead of deleting it.

## Orchestration

`ncm-cognitive` for ground truth and evidence, `khaos-pentest-stages` for phase
gates, and the phase subagents for execution. Three reproductions before a
finding is validated. Two identical failures → change approach; three → stop and
name the blocker. Every turn ends with a file on disk or a concrete diagnosis.
