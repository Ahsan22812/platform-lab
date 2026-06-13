# podinfo

Small Go HTTP service used as the baseline workload across the lab.
Source: <https://github.com/stefanprodan/podinfo>

## What gets deployed

- Namespace: `podinfo`
- Deployment: 3 replicas of `ghcr.io/stefanprodan/podinfo:6.7.0`
- Service: ClusterIP `podinfo.podinfo.svc.cluster.local:80`

Probes hit `/readyz` and `/healthz`. A `/metrics` endpoint is exposed
on port 9898 — used once Prometheus is installed in the next layer.

## Apply

```bash
kubectl apply -f apps/podinfo/podinfo.yaml

# Apply the ServiceMonitor *after* kube-prometheus-stack is installed
# (it provides the ServiceMonitor CRD).
kubectl apply -f apps/podinfo/servicemonitor.yaml
```

## Verify

```bash
kubectl get all -n podinfo
kubectl rollout status deployment/podinfo -n podinfo
kubectl get servicemonitor -n podinfo
```

In Prometheus (port-forward and visit /targets), a new target
`serviceMonitor/podinfo/podinfo/0` should appear with state UP.

## Remove

```bash
kubectl delete -f apps/podinfo/servicemonitor.yaml
kubectl delete -f apps/podinfo/podinfo.yaml
```

## Why podinfo

The unofficial "hello world" of cloud-native demos — used in Flux,
Argo, Linkerd, and Cilium tutorials. Multi-arch (ARM/AMD), small
(~30 MB image), and exposes the endpoints we'll need across later
layers (probes, metrics, traces). Used here strictly as scaffolding;
the real subject of each layer is the platform component, not the app.
