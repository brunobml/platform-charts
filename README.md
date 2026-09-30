# Platform Charts (Golden Path Helm Library)

Centralized repository owned by the **Platform Engineering Team** providing standardized "Golden Path" Helm charts for the enterprise.

Application developers do not write or maintain Kubernetes YAML or Helm charts; they only provide environment values files (`values-dev.yaml`, `values-prod.yaml`) in their application repos.

---

## 📦 Available Charts

| Chart | Version | Purpose | Underlying Technology |
| :--- | :--- | :--- | :--- |
| **`message-processor`** | `1.0.0` | Event-driven microservice worker + web dashboard | Kro ResourceGraphDefinition + AWS ACK SQS |

---

## 🚀 Publishing to Enterprise OCI Registry

Charts in this repository are packaged and pushed as immutable OCI artifacts to the registry:

```bash
# Package and push all charts
make package-all

# Or push a single chart
bash scripts/package-and-push.sh message-processor
```

Published reference: `oci://localhost:5001/charts/message-processor:1.0.0` (in-cluster: `k3d-cloud-registry:5000/charts/message-processor:1.0.0`).

---

## 🚢 GitOps Integration (Argo CD)

Argo CD consumes these charts via its native OCI Helm integration, overlaying simple developer values:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orders-dev
spec:
  sources:
    - chart: message-processor
      repoURL: k3d-cloud-registry:5000/charts
      targetRevision: 1.0.0
      helm:
        valueFiles:
          - $values/deploy/values-dev.yaml
    - repoURL: https://github.com/brunobml/orders-processor.git
      targetRevision: main
      ref: values
```
