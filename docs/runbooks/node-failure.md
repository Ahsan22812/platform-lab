# Node failure

How the lab cluster behaves when a worker node goes down, and how to
recover.

## Simulate

```bash
docker stop platform-lab-worker2     # or platform-lab-worker
```

Each kind "node" is a Docker container, so stopping the container
takes that node offline cleanly.

## Restore

```bash
docker start platform-lab-worker2
```

## Observed timing

Run against this cluster (1 control plane + 2 workers, 3 podinfo
replicas split 2-on-worker2 / 1-on-worker):

| Time after `docker stop` | Event |
|---|---|
| ~0 s        | `docker stop` returns; node container is gone |
| ~10–20 s    | Node shows `NotReady` (kubelet missed heartbeats) |
| ~40 s       | `node-monitor-grace-period` elapses; eviction begins |
| ~40 s+      | Pods on the dead node enter `Terminating` |
| ~90–120 s   | Deployment controller schedules replacement pods on the surviving worker |
| ~120 s      | New pods Ready; cluster is back to 3/3 |

Terminating pods remained `Terminating` until `docker start` brought
the node back — kubelet then confirmed them stopped and the records
finalised.

## Gotchas

- **No auto-rebalance after recovery.** When the dead node returns,
  Kubernetes does not move pods back. Replacements created during the
  outage stay where they landed. The "lost" node sits idle.
- **`Terminating` pods can hang.** If the node is permanently gone
  (real failure, not a simulated stop), the pod records stay in
  `Terminating` forever. Force-delete only when you're certain the
  node will not return:
  ```bash
  kubectl delete pod <name> -n <ns> --grace-period=0 --force
  ```
- **Service stayed up throughout.** The Service automatically removed
  unhealthy endpoints. Traffic kept flowing to the surviving pod the
  whole time — no manual intervention needed.

## Force a rebalance

To redistribute pods after a node returns (or any time the placement
looks wrong):

```bash
kubectl rollout restart deployment/<name> -n <ns>
```

This triggers a rolling restart. Each new pod gives the scheduler a
fresh chance to pick a node, so distribution naturally rebalances.

## What I'd do differently in production

- Add `topologySpreadConstraints` (or `podAntiAffinity`) on workloads
  that must remain spread — especially anything quorum-based
  (Postgres, Kafka, etcd). Without it, after a single node failure
  all replicas can end up co-located.
- Keep `node-monitor-grace-period` and pod-eviction timeouts at
  defaults unless there's a specific reason. Aggressive eviction
  causes thrashing on flaky networks; long timeouts delay recovery.
- Monitor pod distribution as a metric, not just pod count. Three
  pods all on one node looks healthy to a basic check but is one
  failure away from total outage.
