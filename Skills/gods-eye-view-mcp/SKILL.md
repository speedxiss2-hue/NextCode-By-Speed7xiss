---
name: gods-eye-view-mcp
description: Visual grounding and OSINT globe tools modeled on God's Eye View. Load when an agent needs screenshots, live maps, or public-signal context.
---

# God's Eye View — visual and globe context

Use the `vision` subagent for screenshot reading and the `osint-globe` subagent
for public-signal questions.

## Visual grounding

1. Capture or receive the viewport image.
2. Read it with the `read` tool or the `vision` subagent.
3. Report only legible text and visible geometry: signage, labels, coordinates,
   buildings, aircraft, vessels.
4. Combine with live scene context (coordinates, active layers, scale) before
   answering. Never hallucinate a label that is not visible.

## MCP setup (when God's Eye View is installed locally)

Register the server in global `opencode.json`, then use its tools from a session:

```jsonc
{
  "mcp": {
    "servers": {
      "gev": {
        "type": "local",
        "command": ["node", "C:/path/to/gods-eye-view/mcp/dist/index.js"]
      }
    }
  }
}
```

The server exposes map actions (fly to place, set layer, track target, draw
annotation, query live counts). It also lets agents add findings to a shared
canvas.

## Public-signal layers (keyless where noted)

Live flights (OpenSky/adsb.lol), military ADS-B, satellites (CelesTrak),
earthquakes (USGS), fires (WFIGS/NIFC), public cameras, weather (NOAA GFS/ECMWF),
cyclones, radio, transit, vessels (AISStream, free key).

State when a feed is stale or running on a fallback. An estimate is labelled an
estimate — camera poses and traffic positions are not ground truth.
