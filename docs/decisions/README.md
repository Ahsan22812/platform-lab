# Architecture Decision Records (ADRs)

Short markdown files capturing **why** a particular technical choice was made.
Each ADR is immutable once accepted — if a decision is reversed, write a new
ADR that supersedes the old one.

## Format

```
# NNNN: <Title>

## Status
Proposed | Accepted | Superseded by [NNNN](NNNN-...).md)

## Context
What problem are we solving? What constraints apply?

## Decision
What did we decide to do?

## Consequences
- ➕ Positive outcomes
- ➖ Trade-offs accepted
```

## Index

- [0001: Use Colima over OrbStack](0001-colima-over-orbstack.md)
- [0002: Use kind over k3d](0002-kind-over-k3d.md)
- [0003: Single monorepo over polyrepo](0003-monorepo.md)
