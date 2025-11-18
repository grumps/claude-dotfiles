# Helm Chart Exploration and Validation

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

## Common User Workflows

### "I want to use Chart X - what values can I set?"

1. Show all available values: `just helm-show <chart>`
2. Explain the structure and important sections
3. Provide a starter values file with common customizations
4. Show examples from the README

### "Does my values file work with this chart?"

1. Validate: `just helm-validate <chart> <values-file>`
2. Render: `just helm-render <chart> <values-file>`
3. Review output for correctness
4. Check resource limits, replicas, etc.

### "What changes if I modify these values?"

1. Compare: `just helm-compare <chart> <old-values> <new-values>`
2. Explain the diff in plain language
3. Identify potential issues (e.g., resource changes, breaking configs)

### "I'm iterating on values - help me test quickly"

1. Use watch mode: `just helm-watch <chart> <values-file>`
2. Or create a quick validation loop
3. Suggest using helm-test for fast validate + render

## Best Practices to Suggest

1. **Always pin versions** - Use `--version` flag for reproducibility
2. **Validate before deploy** - Run validation and rendering locally first
3. **Layer values files** - Base config + environment-specific overrides
4. **Check resource limits** - Ensure requests/limits are set
5. **Review generated manifests** - Don't blindly trust, inspect output
6. **Use kubectl dry-run** - Validate against actual cluster if available

## Example Conversation Flow

**User**: "Help me configure the bitnami/postgresql chart"

**You**:
1. "Let me show you all available values for bitnami/postgresql"
2. Run: `just helm-show bitnami/postgresql`
3. Explain key sections (auth, persistence, resources, etc.)
4. Create a starter values.yaml with common settings
5. "Now let's validate this configuration"
6. Run: `just helm-test bitnami/postgresql values.yaml`
7. Review output and explain what resources will be created
8. Suggest any improvements

## Integration with Just

All workflows should use Just recipes when possible:

```bash
# Explore chart
just helm-explore bitnami/nginx

# Show values (optionally with version)
just helm-show bitnami/nginx
just helm-show bitnami/nginx 15.0.0

# Render with values
just helm-render bitnami/nginx my-values.yaml

# Validate
just helm-validate bitnami/nginx my-values.yaml

# Test (validate + render)
just helm-test bitnami/nginx my-values.yaml

# Compare
just helm-compare bitnami/nginx old.yaml new.yaml

# Watch for changes
just helm-watch bitnami/nginx my-values.yaml
```

## Output Directory

Rendered charts are saved to `./helm-output/<chart-name>/` by default. This keeps user workspace clean and organized.

## Error Handling

If validation or rendering fails:
1. Explain the error in plain language
2. Show the specific value causing the issue
3. Suggest a fix
4. Provide corrected values if possible

## Notes

- This is **user-level tooling**, not project automation
- Focus on **exploration and validation** of third-party charts
- Help users **understand values** before deploying
- Provide **quick feedback loops** for iterating on configurations
- Keep it **simple and interactive**

Now help the user explore and validate their Helm charts!
