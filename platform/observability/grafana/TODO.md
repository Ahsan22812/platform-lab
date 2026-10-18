# TODO

## Move admin credentials to a Secret sourced from Vault

**Status**: temporary; refactor scheduled for **Layer 5** (Vault +
External Secrets Operator).

### Current state (updated with the GitOps conversion, 2026-10-18)

The values half of the fix is **done** — the umbrella conversion removed
`install.sh` (and its `--set-string adminPassword`) entirely, and
`values.yaml` now references:

```yaml
admin:
  existingSecret: grafana-admin
  userKey: admin-user
  passwordKey: admin-password
```

The remaining debt is only the Secret's **origin**: `grafana-admin` is
created **manually, once, never committed**:

```bash
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password=<yours>
```

### Target shape (Layer 5)

The same `grafana-admin` Secret produced by an `ExternalSecret` pulling
from a Vault KV path instead of by hand — a config-only change; nothing
else in this component moves.

### Trigger to fix

When Layer 5 (Vault + ESO) is up. Apply the same pattern to any other
chart that takes credentials (Alertmanager receivers, Loki S3 creds,
etc.).

### Related

When external access lands (see roadmap "External access" milestone),
also disable anonymous access, lock down the native login form, and
have Grafana trust the proxy's identity (`auth.proxy`/JWT) so SSO can't
be sidestepped.
