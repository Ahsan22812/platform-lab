# 0003: Single monorepo over polyrepo

## Status

Accepted — 2026-05-26

## Context

The lab spans several distinct concerns: cluster definition,
observability, security, GitOps, backup, secrets, networking, and
sample workloads. A natural early question is whether to split these
into multiple repositories or keep them together.

Alternatives considered:

- **One repo per concern** (e.g. `lab-observability`, `lab-security`,
  `lab-networking`, ...). Mirrors how some enterprise teams organise
  infrastructure when different teams own different components.
- **One repo per layer** (platform-repo + apps-repo + scenarios-repo).
- **Single monorepo** with folder-level separation.

The lab has one owner (one person) and no team-boundary, access-control,
or release-cadence constraints that would drive a split.

## Decision

Use a **single monorepo**: `platform-lab`.

Separation between concerns is provided by the folder structure
(`platform/observability/`, `platform/security/`, etc.) rather than by
repository boundaries.

## Consequences

- ➕ Cross-component changes happen in one commit. Example: adding a new
  platform tool and a NetworkPolicy and a runbook is a single PR, not
  three.
- ➕ The architecture story is visible in one place — newcomers and
  future-me can see how the pieces fit by browsing one tree.
- ➕ ADRs, runbooks, and scripts live alongside the things they describe,
  not in a separate "docs repo."
- ➕ Setup is one `git clone` away.
- ➖ Forfeits per-component access control (irrelevant for a solo repo).
- ➖ The repo will eventually grow large. Acceptable — typical infra
  monorepos at midsize companies are 10–50 k files; a personal lab
  will stay well below that for years.

## Notes

If a sub-tree later develops genuinely independent characteristics (its
own release cadence, external consumers, a build/CI pipeline of its
own), it can be extracted into a standalone repository at that point.
The cost of extraction later is small; the cost of premature splitting
now is real.
