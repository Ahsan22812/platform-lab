# 0004: Vendor third-party Helm charts into the repo

## Status

Accepted — 2026-06-10

## Context

Platform components (kube-prometheus-stack, Grafana, soon Loki and
others) are installed from third-party Helm charts. The original
install scripts fetched charts from remote repositories at install
time (`helm repo add` + `helm repo update` + `helm upgrade --install
--version X`).

That makes every install depend on a third party being reachable,
unchanged, and still maintained at the moment of install. This stopped
being theoretical during Layer 2: the `grafana/helm-charts` repository
deprecated **all** of its charts in January 2026 and migrated them to
`grafana-community/helm-charts` — the chart version this repo had
pinned now only exists in a dead repo.

A pinned `--version` protects against surprise upgrades, but not
against the repo disappearing, the index being re-published, or a
tag being re-pointed. The bytes installed are whatever the remote
serves that day.

Alternatives considered:

- **Remote repo at install time** (status quo) — simplest, no binaries
  in git. Every install has a runtime dependency on upstream repo
  availability and integrity.
- **Vendor the chart tarball into the repo** — commit the exact
  `.tgz` per component, install from the local file. Reviewable,
  reproducible, survives upstream death. Costs: binaries in git,
  manual bump procedure.
- **Private Helm/OCI registry** (Harbor, ChartMuseum, ECR/OCI) — the
  production end-state: charts (and images) proxied and pinned through
  infrastructure you control. Overkill right now: there is no registry
  layer in the lab yet, and it solves the same problem with much more
  moving machinery.

## Decision

**Vendor the charts** — the strong intermediate, revisited when a
registry exists.

Layout per component:

```
platform/<area>/<component>/charts/<chart>-<version>.tgz
platform/<area>/<component>/charts/<chart>-<version>.tgz.sha256
platform/<area>/<component>/charts/SOURCE.txt
```

- The `.sha256` is generated at pull time; `install.sh` verifies it
  before installing, so later tampering or corruption fails loudly.
- `SOURCE.txt` records provenance: upstream repo, exact pull command,
  pull date, and the bump procedure.
- Install scripts use **only** the local tarball — no `helm repo add`,
  no network fetch for the chart.
- The root-anchored `charts/*.tgz` ignore rule does not match these
  nested paths; vendored charts are tracked by git deliberately.

## Consequences

- ➕ Installs are reproducible: the bytes reviewed in git are the bytes
  deployed, independent of upstream repo availability or history
  rewrites.
- ➕ Chart upgrades become explicit, reviewable diffs (new tarball +
  checksum + SOURCE.txt change in one commit).
- ➕ Checksum verification at install time catches corruption and
  tampering between pull and deploy.
- ➖ Binary tarballs live in git. Acceptable at this scale (tens of
  KB–single MB per chart, a handful of components).
- ➖ Version bumps are a manual procedure (documented in each
  `SOURCE.txt`) — no `helm repo update` convenience.
- ➖ **This removes only the chart-source dependency.** Container
  images still pull from upstream registries (quay.io, docker.io,
  registry.k8s.io) at install time, and Grafana dashboards still
  download from grafana.com. Full air-gap parity would additionally
  need mirrored images and vendored dashboard JSON — out of scope
  here.

## Notes

This is deliberately an intermediate pattern, not the final shape.
When the lab grows a registry/GitOps layer, revisit with a private
OCI registry serving both charts and mirrored images — at that point
the vendored tarballs and this ADR get superseded.
