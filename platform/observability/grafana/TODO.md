# TODO

## Move admin credentials to a Secret sourced from Vault

**Status**: temporary; refactor scheduled for **Layer 5** (Vault +
External Secrets Operator).

### Current state

`install.sh` accepts `GRAFANA_ADMIN_PASSWORD` (default `admin`) and
passes it via `--set-string adminPassword=...`. Fine for a local lab,
wrong for production:

- Credentials shouldn't pass through Helm values at install time (they
  land in the release's stored values, visible to anyone with helm
  access).
- The password should live in a real Kubernetes Secret, referenced by
  the chart via `admin.existingSecret`.
- That Secret should be synced from Vault by External Secrets Operator,
  not created by hand.

### Target shape (Layer 5)

`values.yaml`:

```yaml
admin:
  existingSecret: grafana-admin
  userKey: admin-user
  passwordKey: admin-password
```

The `grafana-admin` Secret is produced by an `ExternalSecret` pulling
from a Vault KV path. `install.sh` stops touching the password entirely.

### Trigger to fix

When Layer 5 (Vault + ESO) is up. Apply the same pattern to any other
chart that takes credentials (Alertmanager receivers, Loki S3 creds,
etc.).

### Related

When external access lands (see roadmap "External access" milestone),
also disable anonymous access, lock down the native login form, and
have Grafana trust the proxy's identity (`auth.proxy`/JWT) so SSO can't
be sidestepped.
