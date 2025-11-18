# Kustomize Style Guide

Kustomize manages Kubernetes configurations using a base + overlay pattern.

## Core Principles

1. **Base** - Shared configuration across all environments
2. **Overlays** - Environment-specific patches (only what differs)
3. **Strategic merge patches** - Preferred for readability
4. **Pin versions** - Use specific image tags in production

## Structure

```
k8s/
├── base/
│   ├── kustomization.yaml
│   └── deployment.yaml
└── overlays/
    └── dev/
        ├── kustomization.yaml
        └── deployment-patch.yaml
```

## Base Kustomization

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml

images:
  - name: myapp
    newName: ghcr.io/myorg/myapp
    newTag: latest
```

## Overlay Kustomization

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: myapp-dev

images:
  - name: myapp
    newTag: v1.2.3

patchesStrategicMerge:
  - deployment-patch.yaml
```

## Patch Example

```yaml
# deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: myapp
          resources:
            requests:
              memory: "512Mi"
              cpu: "500m"
```

## Usage

```bash
# Build
kustomize build overlays/dev

# Apply
kubectl apply -k overlays/dev

# Validate
kustomize build overlays/dev | kubectl apply --dry-run=client -f -
```

## Resources

- [Official Docs](https://kustomize.io/)
- See `examples/kustomize/` for working example
