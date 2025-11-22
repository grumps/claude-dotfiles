# Helm Chart Exploration and Validation Guide

User-level tooling for exploring third-party Helm charts, understanding configuration options, and validating custom values.

## Overview

The `helm-chart-render.sh` script helps you work with Helm charts at the user level:

- **Explore third-party charts** - Understand what values are available
- **Validate configurations** - Test custom values files before deployment
- **Render manifests** - See what Kubernetes resources will be created
- **Compare configurations** - Understand differences between values files
- **Support OCI and traditional repos** - Work with any chart source

This is **user-level tooling**, not project-specific automation. Use it to explore and validate charts before deploying them.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Exploring Charts](#exploring-charts)
4. [Validating Values](#validating-values)
5. [Rendering Charts](#rendering-charts)
6. [Repository Management](#repository-management)
7. [Just Recipes](#just-recipes)
8. [Common Workflows](#common-workflows)
9. [Best Practices](#best-practices)

## Quick Start

```bash
# Add a chart repository
scripts/helm-chart-render.sh add-repo --name bitnami --url https://charts.bitnami.com/bitnami

# Explore a chart - see all available values
scripts/helm-chart-render.sh show-values --chart bitnami/nginx

# Create a custom values file (my-nginx.yaml)
# Then validate and render
scripts/helm-chart-render.sh validate --chart bitnami/nginx --values my-nginx.yaml
scripts/helm-chart-render.sh render --chart bitnami/nginx --values my-nginx.yaml --output ./helm-output/nginx

# Using Just recipes (recommended)
just helm-explore bitnami/nginx
just helm-test bitnami/nginx my-nginx.yaml
```

## Installation

The script requires:

- **Helm 3.x** - [Installation Guide](https://helm.sh/docs/intro/install/)
- **kubectl** (optional) - For manifest validation

```bash
# Verify installation
helm version

# Script is executable after dotfiles setup
ls -l ~/.claude-dotfiles/scripts/helm-chart-render.sh
```

## Exploring Charts

### Discover What Values Are Available

Before using a chart, understand what you can configure:

```bash
# Show all available values
scripts/helm-chart-render.sh show-values --chart bitnami/nginx

# Show values for specific version
scripts/helm-chart-render.sh show-values --chart bitnami/nginx --version 15.0.0

# Using Just
just helm-show bitnami/nginx
just helm-show bitnami/nginx 15.0.0
```

### View Chart Information

```bash
# Chart metadata (version, description, dependencies)
helm show chart bitnami/nginx

# Full README with usage instructions
helm show readme bitnami/nginx

# Using Just
just helm-info bitnami/nginx
just helm-readme bitnami/nginx
```

### Search for Charts

```bash
# Search across all added repositories
helm search repo nginx

# Search for specific chart
helm search repo postgresql

# Using Just
just helm-search nginx
```

### Complete Exploration

Get everything about a chart in one command:

```bash
# Shows: chart info + values + README
just helm-explore bitnami/nginx
```

## Validating Values

### Validate Custom Values Files

Before deploying, validate your values file:

```bash
# Basic validation
scripts/helm-chart-render.sh validate \
  --chart bitnami/nginx \
  --values my-values.yaml

# Strict validation (recommended)
scripts/helm-chart-render.sh validate \
  --chart bitnami/nginx \
  --values my-values.yaml \
  --strict

# Using Just
just helm-validate bitnami/nginx my-values.yaml
```

### Compare Configurations

Understand what changes between two values files:

```bash
# Compare two configurations
scripts/helm-chart-render.sh diff \
  --chart bitnami/nginx \
  --values-a current-values.yaml \
  --values-b new-values.yaml

# Using Just
just helm-compare bitnami/nginx current-values.yaml new-values.yaml
```

## Rendering Charts

### Render with Custom Values

See what Kubernetes manifests will be generated:

```bash
# Render chart with custom values
scripts/helm-chart-render.sh render \
  --chart bitnami/nginx \
  --values my-values.yaml \
  --namespace production \
  --output ./helm-output/nginx

# Using Just (auto-generates output path)
just helm-render bitnami/nginx my-values.yaml
just helm-render bitnami/nginx my-values.yaml production
```

**Output:**

- `helm-output/nginx/all-manifests.yaml` - All resources in one file
- `helm-output/nginx/Deployment-*.yaml` - Individual resource files
- Resource summary with counts
- YAML syntax validation

### Render from Local Chart

```bash
# Render a local chart directory
scripts/helm-chart-render.sh render \
  --chart ./path/to/chart \
  --values my-values.yaml \
  --output ./helm-output/mychart
```

### Render from OCI Registry

```bash
# Render from OCI with authentication
scripts/helm-chart-render.sh render \
  --chart oci://registry.example.com/charts/myapp \
  --version 1.2.3 \
  --values my-values.yaml \
  --username myuser \
  --password "${REGISTRY_PASSWORD}" \
  --output ./helm-output/myapp
```

### Validate and Render Together

Quick workflow to validate then render:

```bash
# Validate + render in one command
just helm-test bitnami/nginx my-values.yaml
```

### Watch Mode (Development)

Auto-re-render when values file changes:

```bash
# Watch for changes and re-render
just helm-watch bitnami/nginx my-values.yaml
```

Requires: `fswatch` (macOS) or `inotify-tools` (Linux)

## Repository Management

### Add Traditional Helm Repository

```bash
# Public repository
scripts/helm-chart-render.sh add-repo \
  --name bitnami \
  --url https://charts.bitnami.com/bitnami

# Private repository with basic auth
scripts/helm-chart-render.sh add-repo \
  --name mycompany \
  --url https://charts.mycompany.com \
  --username myuser \
  --password "${HELM_PASSWORD}"

# Using Just
just helm-add-repo bitnami https://charts.bitnami.com/bitnami
```

### Add OCI Registry

```bash
# OCI registry with authentication
echo "${PASSWORD}" | scripts/helm-chart-render.sh add-repo \
  --name myregistry \
  --url oci://registry.example.com/charts \
  --username myuser \
  --password-stdin

# Using Just
echo "${PASSWORD}" | just helm-add-oci myregistry oci://registry.example.com/charts myuser
```

### Update Repositories

```bash
# Update all repositories to get latest charts
helm repo update

# Using Just
just helm-update
```

### List Repositories

```bash
# Show all added repositories
helm repo list

# Using Just
just helm-repos
```

## Just Recipes

Import the Helm justfile to get all recipes:

```just
# In your justfile
import '~/.claude-dotfiles/examples/justfiles/helm.just'
```

### Exploration Recipes

```bash
# Show all values
just helm-show CHART [VERSION]

# Chart information
just helm-info CHART

# Chart README
just helm-readme CHART

# Complete exploration
just helm-explore CHART

# Search for charts
just helm-search KEYWORD
```

### Validation Recipes

```bash
# Validate values file
just helm-validate CHART VALUES_FILE

# Validate and render
just helm-test CHART VALUES_FILE [NAMESPACE]

# Compare configurations
just helm-compare CHART VALUES_A VALUES_B
```

### Rendering Recipes

```bash
# Render with values
just helm-render CHART VALUES_FILE [NAMESPACE]

# Render with multiple values files
just helm-render-multi CHART OUTPUT VALUES...

# Render with --set overrides
just helm-render-set CHART VALUES_FILE OUTPUT SETS...

# Watch mode
just helm-watch CHART VALUES_FILE
```

### Repository Recipes

```bash
# Add repository
just helm-add-repo NAME URL

# Add OCI registry (with stdin password)
just helm-add-oci NAME URL USERNAME

# Update repositories
just helm-update

# List repositories
just helm-repos
```

### Utility Recipes

```bash
# Clean rendered output
just helm-clean
```

## Common Workflows

### Workflow 1: Understanding a New Chart

**Goal:** Learn what a third-party chart does and how to configure it

```bash
# 1. Add repository if needed
just helm-add-repo bitnami https://charts.bitnami.com/bitnami
just helm-update

# 2. Explore the chart
just helm-explore bitnami/postgresql

# 3. Review values and identify key settings
just helm-show bitnami/postgresql

# 4. Read the README for usage instructions
just helm-readme bitnami/postgresql
```

**Or use Claude:**

```text
/helm-render
User: "Help me understand the bitnami/postgresql chart"
```

### Workflow 2: Creating and Testing Custom Values

**Goal:** Create a custom values file and validate it works

```bash
# 1. See default values
just helm-show bitnami/nginx > default-values.yaml

# 2. Create custom values file (my-nginx.yaml)
cat > my-nginx.yaml <<EOF
replicaCount: 3
image:
  tag: "1.25.0"
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF

# 3. Validate and render
just helm-test bitnami/nginx my-nginx.yaml

# 4. Review generated manifests
cat helm-output/nginx/all-manifests.yaml
```

### Workflow 3: Comparing Configuration Changes

**Goal:** Understand impact of changing values

```bash
# 1. Current configuration
cat > current.yaml <<EOF
replicaCount: 2
resources:
  limits:
    memory: 256Mi
EOF

# 2. Proposed configuration
cat > proposed.yaml <<EOF
replicaCount: 5
resources:
  limits:
    memory: 512Mi
EOF

# 3. Compare
just helm-compare bitnami/nginx current.yaml proposed.yaml

# 4. Review diff and understand impact
```

### Workflow 4: Iterating on Values

**Goal:** Quickly test changes while editing values

**Terminal 1:**

```bash
# Start watch mode
just helm-watch bitnami/nginx my-values.yaml
```

**Terminal 2:**

```bash
# Edit values file
vim my-values.yaml
# Save - watch mode auto-re-renders
```

### Workflow 5: Validating Before Deployment

**Goal:** Ensure configuration is correct before deploying to cluster

```bash
# 1. Validate values
just helm-validate bitnami/nginx prod-values.yaml

# 2. Render manifests
just helm-render bitnami/nginx prod-values.yaml production

# 3. Review resource definitions
ls -la helm-output/nginx/

# 4. Kubectl dry-run (if you have cluster access)
kubectl apply --dry-run=server -f helm-output/nginx/all-manifests.yaml

# 5. Deploy when ready
helm upgrade --install my-nginx bitnami/nginx \
  --namespace production \
  --values prod-values.yaml \
  --create-namespace
```

## Best Practices

### 1. Always Explore First

Before using a chart, understand its values:

```bash
just helm-explore <chart>
```

### 2. Pin Versions

Always specify chart versions for reproducibility:

```bash
# Bad - uses latest version (changes over time)
just helm-show bitnami/nginx

# Good - pinned to specific version
just helm-show bitnami/nginx 15.0.0
```

### 3. Validate Before Deploy

Never deploy without validation:

```bash
just helm-validate <chart> <values-file>
just helm-render <chart> <values-file>
# Review output
# Then deploy
```

### 4. Layer Values Files

Use multiple values files for different environments:

```bash
# Base configuration
cat > base-values.yaml <<EOF
replicaCount: 2
EOF

# Production overrides
cat > prod-values.yaml <<EOF
replicaCount: 5
resources:
  limits:
    cpu: 1000m
EOF

# Render with both
scripts/helm-chart-render.sh render \
  --chart bitnami/nginx \
  --values base-values.yaml \
  --values prod-values.yaml \
  --output ./helm-output/nginx-prod
```

### 5. Review Generated Manifests

Always inspect what will be deployed:

```bash
just helm-render bitnami/nginx my-values.yaml
cat helm-output/nginx/all-manifests.yaml
```

### 6. Use Semantic Values

Create meaningful, documented values files:

```yaml
# Good - clear and documented
replicaCount: 3  # Scale for production load
image:
  tag: "1.25.0"  # Latest stable as of 2024-01

# Avoid - unclear
x: 3
t: "1.25.0"
```

### 7. Keep Output Organized

Use consistent output directories:

```bash
# Organized by chart
just helm-render bitnami/nginx my-values.yaml
# → helm-output/nginx/

just helm-render bitnami/postgresql my-values.yaml
# → helm-output/postgresql/

# Clean when done
just helm-clean
```

## Advanced Usage

### Multiple Values Files

```bash
# Layer multiple values files
just helm-render-multi bitnami/nginx ./helm-output/nginx \
  base-values.yaml \
  env-prod.yaml \
  secrets.yaml
```

### Command-Line Overrides

```bash
# Override specific values
just helm-render-set bitnami/nginx base-values.yaml ./helm-output/nginx \
  "image.tag=1.25.1" \
  "replicaCount=5"
```

### Working with OCI Charts

```bash
# Login to OCI registry
helm registry login registry.example.com -u myuser

# Render from OCI
scripts/helm-chart-render.sh render \
  --chart oci://registry.example.com/charts/myapp \
  --version 1.2.3 \
  --values my-values.yaml \
  --output ./helm-output/myapp
```

### Local Chart Development

```bash
# Work with local chart
just helm-render ./my-local-chart my-values.yaml

# Validate local chart
just helm-validate ./my-local-chart my-values.yaml
```

## Troubleshooting

### Chart Not Found

```bash
# Check repositories
helm repo list

# Update repositories
helm repo update

# Search for chart
helm search repo <chart-name>
```

### Authentication Failed

```bash
# For traditional repos
helm repo add myrepo https://charts.example.com \
  --username myuser \
  --password mypass

# For OCI registries
helm registry login registry.example.com \
  --username myuser
```

### Values Validation Failed

```bash
# Check YAML syntax
yamllint my-values.yaml

# See default values for reference
just helm-show <chart>

# Try rendering to see specific error
just helm-render <chart> my-values.yaml
```

### Rendering Failed

```bash
# Enable debug mode
helm template test-release <chart> \
  --values my-values.yaml \
  --debug

# Check for required values
helm show values <chart> | grep -i required
```

## Integration with Claude Code

Use the `/helm-render` slash command in Claude Code:

```text
/helm-render
```

Claude will help you:

- Explore chart values
- Create starter configurations
- Validate your values files
- Explain differences between configurations
- Suggest best practices

## Related Documentation

- [Helm Documentation](https://helm.sh/docs/)
- [Quick Reference](./QUICK_REFERENCE.md) - Command cheat sheet
- [Claude Dotfiles README](../README.md) - Overall documentation

---

**Remember:** This is user-level tooling for exploring and validating charts. Use it to understand third-party charts before deploying them!
