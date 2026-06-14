# charts

Helm charts we author. One directory per chart; all siblings, so a
chart depends on the shared library with a short uniform path
(`file://../common`).

```
charts/
  common/      # shared LIBRARY chart (type: library) — renders nothing
               # itself; exports common.pdb / topologySpread /
               # servicemonitor + label helpers. See its _*.tpl files.
  podinfo/     # deployment chart for podinfo (third-party app, no source)
  <service>/   # deployment chart for one of our own apps/ services
```

- **Application *source*** lives in [`../apps/`](../apps/), not here —
  these are deployment charts only.
- **Vendored third-party charts** (kube-prometheus-stack, grafana) are
  separate — they live under `platform/observability/*/charts/` as
  pinned `.tgz` (see ADR 0004), because they're consumed, not authored.
- Each chart's own `charts/` subdir (Helm's dependency cache) is
  gitignored and rebuilt by `helm dependency update`.

Future (Layer 3.5): publish `common` to the OCI registry and consume it
via `oci://… --version x.y.z` instead of `file://` — closes the
relative-path bootstrap.
