# Kubernetes-specific recipes

# Validate K8s manifests (dry-run)
k8s-validate:
  kubectl apply --dry-run=client -f k8s/ 2>&1

# Lint K8s YAML files
k8s-lint:
  yamllint -c .yamllint.yaml k8s/

# Validate K8s with kubeconform (if available)
k8s-conform:
  #!/usr/bin/env bash
  if command -v kubeconform &> /dev/null; then
    kubeconform -summary k8s/
  else
    echo "⚠️  kubeconform not installed, skipping"
  fi

# Show current kubectl context
k8s-context:
  @echo "Current context: $(kubectl config current-context)"
  @echo "Current namespace: $(kubectl config view --minify -o jsonpath='{..namespace}')"

# Run all K8s checks
k8s-check: k8s-lint k8s-validate k8s-conform

# Kustomize recipes

# Build kustomize overlay
kustomize-build ENV:
  kustomize build k8s/overlays/{{ENV}}

# Validate kustomize overlays
kustomize-validate:
  #!/usr/bin/env bash
  set -euo pipefail
  for overlay in k8s/overlays/*/; do
    env=$(basename "$overlay")
    echo "Validating $env..."
    kustomize build "$overlay" | kubectl apply --dry-run=client -f - > /dev/null
  done
  echo "✅ All overlays validated"

# Show diff vs cluster
kustomize-diff ENV:
  kustomize build k8s/overlays/{{ENV}} | kubectl diff -f -

# Apply to cluster
kustomize-apply ENV:
  @echo "Applying {{ENV}} to $(kubectl config current-context)"
  @read -p "Continue? (y/N) " -n 1 -r; echo; \
  [[ $$REPLY =~ ^[Yy]$$ ]] && kustomize build k8s/overlays/{{ENV}} | kubectl apply -f -
