# 0001: Use Colima over OrbStack

## Status

Accepted — 2026-05-26

## Context

The lab needs a container runtime on macOS (Apple Silicon) to back
`kind` and any ad-hoc Docker work. Docker Desktop is the obvious default
but is heavy, slow on M1 historically, and increasingly commercial.

Alternatives considered:

- **Docker Desktop** — most familiar but heaviest on RAM, requires a
  license for many use cases, slower filesystem on M1.
- **OrbStack** — fastest and most polished on macOS. Free for personal
  use, paid for work use. Closed source. **macOS only.**
- **Colima** — FOSS (MIT), Lima-based, available on macOS and Linux.
  Slightly less polished than OrbStack but very close in performance.
- **Lima directly** — too low-level for daily use.

The lab is for personal learning and is expected to outlive any single
machine. Skills and configs should be portable.

## Decision

Use **Colima** as the container runtime.

## Consequences

- ➕ Fully free, no license ambiguity now or later.
- ➕ Available on macOS *and* Linux — the same setup transfers to any
  future Linux box (home server, cloud VM, work laptop).
- ➕ Lightweight: ~400 MB idle, well below Docker Desktop's ~2 GB.
- ➕ Provides a standard Docker socket — every Docker tutorial works
  unchanged.
- ➖ CLI only, no GUI. Status checks via `colima status`.
- ➖ Slightly less polish than OrbStack (occasional VM restart needed).
- ➖ Performance is very close to OrbStack but not quite as fast.

## Notes

If a need arises that Colima can't meet (e.g. very GUI-heavy workflow
or specific Apple framework integration), OrbStack remains a clean
swap-in — both expose the same Docker socket.
