---
name: ncm-cognitive
description: Next-Concept Modeling layer — ground-truth manifest, evidence ledger, state matrix, failure breakers. Load before any long build, reverse-engineering, or pentest task.
---

# NCM 2.0 — cognitive layer

Hybrid loop: deterministic ground-truth inspection first, model inference second.
The model never guesses what exists on disk; the host tells it.

## Ground-truth manifest (0 tokens)

Before reasoning about a request that names files or paths:
1. Extract every path/symbol mentioned in the prompt and history.
2. Check each one on disk with `Test-Path`/`glob`/`grep`.
3. Inject a manifest: CONFIRMED paths, MISSING paths, and the real CWD.
4. Only then plan. Never read a missing path or rewrite a file unnecessarily.

## Thirteen concepts

C1 intent decomposition · C2 topology mapping · C3 ground truth · C4 syntactic
blueprint · C5 multi-tool chaining · C6 deterministic execution · C7 outcome
verification · C8 failure healing · C9 memory distillation · C10 convergent
delivery · C11 hypothesis tree · C12 ephemeral harness · C13 milestone DAG.

## State matrix

- H1 direct action — edit/create with context already mapped → execute now.
- H2 multi-tool chain — ordered stages → parallelise independent reads.
- H3 self-heal — compile/syntax failure → diagnose root cause, mutate approach.
- H4 physical verification — after any disk mutation → compile, run, assert.
- H5 memory distillation — stable pattern found → append to session_memory.json.

## Evidence ledger

Classify every claim:
- OBSERVED — returned by a tool, disk read, or running process.
- INFERRED — direct deduction from observed facts.
- HYPOTHESIS — declared, pending validation.
- UNKNOWN — not inspected; must test before asserting.

A task is never "done" on tool silence or a command that was merely emitted.
Show the exit code, the file, or the test result.

## Failure breakers

- Two identical failures → change strategy.
- Three cycles with no material progress → pause, name the exact blocker,
  state the next required input.
- Rejected tool/permission → re-check runtime flags before retrying.

## Process janitor

Track processes started for builds/scans/servers. Reap anything idle for more
than 60s; lower priority of long jobs; never leave a listener or scanner alive.

## AST index

For repo-scale work, index classes, exported methods, and dependency edges with
`grep`/`glob` first. Feed the compact index into context instead of recursively
reading every file.
