# Helm user-level tooling for exploring and validating third-party charts
# Import this file into your main justfile with: import 'path/to/helm.just'

# Path to helm-chart-render.sh script
HELM_RENDER_SCRIPT := "~/.claude-dotfiles/scripts/helm-chart-render.sh"

# === Exploring Third-Party Charts ===

# Show all available values for a chart
helm-show CHART *VERSION:
  #!/usr/bin/env bash
  if [[ -n "{{VERSION}}" ]]; then
    {{HELM_RENDER_SCRIPT}} show-values --chart {{CHART}} --version {{VERSION}}
  else
    {{HELM_RENDER_SCRIPT}} show-values --chart {{CHART}}
  fi

# Show chart information (version, description, etc.)
helm-info CHART:
  #!/usr/bin/env bash
  if command -v helm &> /dev/null; then
    helm show chart {{CHART}}
  else
    echo "⚠️  helm not installed"
    exit 1
  fi

# Show chart README
helm-readme CHART:
  #!/usr/bin/env bash
  if command -v helm &> /dev/null; then
    helm show readme {{CHART}}
  else
    echo "⚠️  helm not installed"
    exit 1
  fi

# Search for charts in repositories
helm-search KEYWORD:
  #!/usr/bin/env bash
  if command -v helm &> /dev/null; then
    helm search repo {{KEYWORD}}
  else
    echo "⚠️  helm not installed"
    exit 1
  fi

# === Rendering and Validation ===

# Render a chart with custom values and validate
helm-render CHART VALUES_FILE *NAMESPACE:
  #!/usr/bin/env bash
  NS="${{NAMESPACE:-default}}"
  {{HELM_RENDER_SCRIPT}} render \
    --chart {{CHART}} \
    --values {{VALUES_FILE}} \
    --namespace "$NS" \
    --output "./helm-output/$(basename {{CHART}})"

# Validate values file against a chart
helm-validate CHART VALUES_FILE:
  {{HELM_RENDER_SCRIPT}} validate \
    --chart {{CHART}} \
    --values {{VALUES_FILE}} \
    --strict

# Render and validate in one step
helm-test CHART VALUES_FILE *NAMESPACE: (helm-validate CHART VALUES_FILE) (helm-render CHART VALUES_FILE NAMESPACE)
  @echo "✓ Chart rendered and validated successfully"

# Compare two different values configurations
helm-compare CHART VALUES_A VALUES_B:
  {{HELM_RENDER_SCRIPT}} diff \
    --chart {{CHART}} \
    --values-a {{VALUES_A}} \
    --values-b {{VALUES_B}}

# === Repository Management ===

# Add a traditional Helm repository
helm-add-repo NAME URL:
  {{HELM_RENDER_SCRIPT}} add-repo --name {{NAME}} --url {{URL}}

# Add an OCI repository with authentication
helm-add-oci NAME URL USERNAME:
  {{HELM_RENDER_SCRIPT}} add-repo \
    --name {{NAME}} \
    --url {{URL}} \
    --username {{USERNAME}} \
    --password-stdin

# Update all repositories
helm-update:
  #!/usr/bin/env bash
  if command -v helm &> /dev/null; then
    helm repo update
  else
    echo "⚠️  helm not installed"
    exit 1
  fi

# List all repositories
helm-repos:
  #!/usr/bin/env bash
  if command -v helm &> /dev/null; then
    helm repo list
  else
    echo "⚠️  helm not installed"
    exit 1
  fi

# === Advanced Rendering ===

# Render with multiple values files (layered)
helm-render-multi CHART OUTPUT *VALUES:
  #!/usr/bin/env bash
  values_args=""
  for f in {{VALUES}}; do
    values_args="$values_args --values $f"
  done
  {{HELM_RENDER_SCRIPT}} render \
    --chart {{CHART}} \
    $values_args \
    --output {{OUTPUT}}

# Render with command-line overrides
helm-render-set CHART VALUES_FILE OUTPUT *SETS:
  #!/usr/bin/env bash
  set_args=""
  for s in {{SETS}}; do
    set_args="$set_args --set $s"
  done
  {{HELM_RENDER_SCRIPT}} render \
    --chart {{CHART}} \
    --values {{VALUES_FILE}} \
    $set_args \
    --output {{OUTPUT}}

# === Cleanup ===

# Clean all rendered output
helm-clean:
  @echo "Cleaning helm-output directory..."
  rm -rf ./helm-output
  @echo "✓ Cleaned helm-output/"

# === Quick Workflows ===

# Quick explore: show chart info, values, and README
helm-explore CHART:
  @echo "=== Chart Information ==="
  @just helm-info {{CHART}}
  @echo ""
  @echo "=== Available Values ==="
  @just helm-show {{CHART}}
  @echo ""
  @echo "=== Chart README ==="
  @just helm-readme {{CHART}}

# Watch mode: re-render when values file changes
helm-watch CHART VALUES_FILE:
  #!/usr/bin/env bash
  if command -v fswatch &> /dev/null; then
    echo "Watching {{VALUES_FILE}} for changes..."
    fswatch -o {{VALUES_FILE}} | while read; do
      echo "Re-rendering chart..."
      just helm-render {{CHART}} {{VALUES_FILE}}
    done
  elif command -v inotifywait &> /dev/null; then
    echo "Watching {{VALUES_FILE}} for changes..."
    while inotifywait -e modify {{VALUES_FILE}}; do
      echo "Re-rendering chart..."
      just helm-render {{CHART}} {{VALUES_FILE}}
    done
  else
    echo "⚠️  Install fswatch (macOS) or inotify-tools (Linux) for watch mode"
    exit 1
  fi
