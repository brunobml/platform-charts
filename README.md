# Platform Charts (Golden Path Helm Library)

> **Status: Current** (2026-10-03).

The golden Helm charts of the lab, owned by the platform team. Application teams do not write Kubernetes YAML. They register an app in `tenant-workloads` and keep one small values file per environment in their own repository (for example `orders-processor/deploy/values-dev.yaml`).

---

## 📦 Available Charts

| Chart | Version | Renders | Consumed by |
| :--- | :--- | :--- | :--- |
| **`queue-backed-service`** | `1.0.0` | One kro `QueueBackedService` instance: worker and API Deployments, SQS queue and DLQ (ACK), DynamoDB table, Service and Ingress | the `tenant-workloads` ApplicationSet in `gitops-control-plane` |

The chart only fills the instance. The resource graph itself is the `QueueBackedService` ResourceGraphDefinition in `platform-catalog/blueprints/`. That definition is guarded by the admission policy `queuebackedservice-contract`.

Values (see `charts/queue-backed-service/values.yaml`): `name`, `environment` (`dev` | `test` | `prod`), `replicas`, `retentionPeriod`, and `image`. The image must come from `ghcr.io/brunobml/` and, for `orders-processor`, be cosign-signed by its CI.

---

## 🚀 Releasing (OCI on GHCR, immutable versions)

Charts are published to `oci://ghcr.io/brunobml/charts` by the **release workflow** (`.github/workflows/release.yaml`) on every push to `main`. **A released version is never overwritten:**

| Situation | Workflow result |
|---|---|
| Version not yet in GHCR | packaged and pushed |
| Version exists, packaged content identical | skipped (green) |
| Version exists, content differs | **fails**: bump `version` in `Chart.yaml` |
| Any other registry error | **fails** (never pushes on doubt) |

To release a change: edit the chart, **bump `version`**, push. Then move consumers to the new version in `gitops-control-plane/applicationsets/tenant-workloads.yaml`.

Local helpers:
```bash
make lint          # helm lint every chart
make package-all   # same rule as the workflow: pushes only versions not yet released
                   # (needs `helm registry login ghcr.io`; normally CI does this)
make clean         # remove dist/
```

---

## 🚢 How Argo CD consumes it

The `tenant-workloads` ApplicationSet renders one Application per registration file. Each Application has two sources, the chart and the app repo's values:
```yaml
sources:
  - chart: queue-backed-service
    repoURL: ghcr.io/brunobml/charts
    targetRevision: 1.0.0
    helm:
      valueFiles:
        - $values/deploy/values-dev.yaml        # or the registration's valuesFile
  - repoURL: https://github.com/brunobml/orders-processor.git
    targetRevision: main                      # prod: a full commit SHA
    ref: values
```
