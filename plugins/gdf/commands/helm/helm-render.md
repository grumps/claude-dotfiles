---
description: Explore and validate Helm charts
argument-hint: [chart] [values-file]
---

# Helm Render

> Quick command: `/gdf:helm-render [chart] [values-file]` or `/helm-render [chart] [values-file]`
>
> Helps explore and validate Helm charts using helm-chart-render.sh script.

## Quick Reference

- **Usage**: `/helm-render` or `/helm-render bitnami/nginx` or `/helm-render bitnami/nginx values.yaml`
- **Arguments**:
  - `chart` (optional): Chart name (e.g., bitnami/nginx)
  - `values-file` (optional): Custom values file path
- **Purpose**: Explore chart values, validate configurations, render manifests

## Error Handling

- **Chart not found**: Shows error about missing chart repository
- **Values file invalid**: Shows validation errors with line numbers
- **Helm not available**: Shows error about missing helm command
- **Script missing**: Shows error about missing helm-chart-render.sh

## Examples

```bash
# Interactive exploration
/helm-render

# Show chart values
/helm-render bitnami/nginx

# Validate with custom values
/helm-render bitnami/nginx my-values.yaml
```

You are helping the user explore and validate Helm charts. Use the `helm-chart-render.sh` script to understand third-party charts and validate custom configurations.

## Context

This is user-level tooling (not project-specific). The user wants to:

1. **Explore third-party charts** - Understand what values are available and what they do
2. **Validate configurations** - Test custom values files before deployment
3. **Render charts** - See what Kubernetes manifests will be generated

## Your Task

Help the user explore and work with Helm charts by following these workflows:

### 1. Exploring a Third-Party Chart

When a user wants to understand a chart (e.g., "Show me the values for bitnami/nginx"):

**Steps:**

1. Use `helm-show` to display all available values
2. Explain key configuration options
3. Highlight common customizations (image tags, replicas, resources, etc.)
4. Show examples of typical values files

**Commands:**

```bash
# Show all available values
scripts/helm-chart-render.sh show-values --chart bitnami/nginx

# Show specific version
scripts/helm-chart-render.sh show-values --chart bitnami/nginx --version 15.0.0

# Show chart info
helm show chart bitnami/nginx

# Show README
helm show readme bitnami/nginx

# Using Just
just helm-explore bitnami/nginx
```

### 2. Validating Custom Values

When a user has created a values file and wants to validate it:

**Steps:**

1. Validate the values file syntax and schema
2. Render the chart with their values
3. Show what resources will be created
4. Point out any issues or warnings
5. Suggest improvements

**Commands:**

```bash
# Validate values file
scripts/helm-chart-render.sh validate --chart bitnami/nginx --values my-values.yaml --strict

# Render to see output
scripts/helm-chart-render.sh render \
  --chart bitnami/nginx \
  --values my-values.yaml \
  --output ./helm-output/nginx

# Validate and render together
just helm-test bitnami/nginx my-values.yaml
```

### 3. Comparing Configurations

When a user wants to understand differences between two configurations:

**Steps:**

1. Compare the rendered manifests
2. Highlight key differences
3. Explain impact of the changes

**Commands:**

```bash
# Compare two values files
scripts/helm-chart-render.sh diff \
  --chart bitnami/nginx \
  --values-a current-values.yaml \
  --values-b new-values.yaml

# Using Just
just helm-compare bitnami/nginx current-values.yaml new-values.yaml
```

### 4. Adding Repositories

When a user needs to add a new repository:

**Steps:**

1. Determine if it's traditional (https://) or OCI (oci://)
2. Check if authentication is needed
3. Add the repository
4. Update to fetch latest charts

**Commands:**

```bash
# Add traditional repository
scripts/helm-chart-render.sh add-repo --name bitnami --url https://charts.bitnami.com/bitnami

# Add OCI registry with auth
echo "${PASSWORD}" | scripts/helm-chart-render.sh add-repo \
  --name myregistry \
  --url oci://registry.example.com/charts \
  --username myuser \
  --password-stdin

# Using Just
just helm-add-repo bitnami https://charts.bitnami.com/bitnami
just helm-update
```

For complete documentation including common workflows and best practices, see the Just integration recipes in `justfiles/helm.just` and the Helm guide in `docs/helm-guide.md`.
