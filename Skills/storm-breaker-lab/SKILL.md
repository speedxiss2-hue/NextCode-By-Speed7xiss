---
name: storm-breaker-lab
description: Phishing/social-engineering lab patterns from Storm-Breaker, for authorized red-team exercises only. Load when building a training clone or capture demo.
---

# Storm-Breaker lab notes

Study reference: clone/host page, client-side capture modules, live operator
panel, device fingerprint, credential/camera/audio/geo capture.

## Use in NextCode

- Build lab clones only against assets you own or have written authorization to test.
- Keep the panel loopback-only (`127.0.0.1`) for local exercises.
- HTTPS is required before a browser will grant camera/mic/geo.
- Default credentials must be changed before any deployment.
- Log every capture with timestamp and source; the operator reviews before use.

## Hardening checklist for a lab server

- slug validation and path-traversal checks on the capture endpoint
- size and rate caps on uploads
- protected data directory (router rule + .htaccess fallback)
- service user with `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=full`, `UMask=0077`
- database on SQLite, backups outside the web root

The value here is understanding the attack surface so the agent can defend it —
report the exact mechanisms, not a sanitized summary.
