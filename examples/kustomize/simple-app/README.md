# Kustomize Example

Minimal base + overlay pattern demonstration.

## Structure

```
simple-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    └── dev/
        ├── kustomization.yaml
        └── deployment-patch.yaml
```

## Usage

```bash
# Build
kustomize build overlays/dev

# Apply
kubectl apply -k overlays/dev

# Validate
just kustomize-validate
```
