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
