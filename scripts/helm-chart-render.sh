#!/bin/bash
set -e

# helm-chart-render.sh - A comprehensive Helm chart rendering and validation tool
# Supports traditional Helm repos and OCI registries with authentication

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

header() {
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

A comprehensive Helm chart rendering and validation tool.

Commands:
  add-repo        Add a Helm repository (traditional or OCI)
  render          Render a Helm chart with values
  validate        Validate chart values against schema
  template        Generate and display templated manifests
  show-values     Display default and computed values
  diff            Compare values between files
  help            Display this help message

Add Repository:
  $(basename "$0") add-repo --name <name> --url <url> [options]
  --name <name>         Repository name
  --url <url>           Repository URL (traditional or OCI)
  --username <user>     Username for authentication (optional)
  --password <pass>     Password for authentication (optional)
  --password-stdin      Read password from stdin (optional)
  --insecure-skip-tls   Skip TLS verification (optional)
  --force-update        Force repository update (optional)

Render Chart:
  $(basename "$0") render --chart <chart> [options]
  --chart <chart>       Chart name or path (e.g., myrepo/mychart or ./chart)
  --namespace <ns>      Kubernetes namespace (default: default)
  --release <name>      Release name (default: test-release)
  --values <file>       Values file(s), can be specified multiple times
  --set <key=value>     Set values on command line, can be specified multiple times
  --version <version>   Chart version (optional)
  --output <dir>        Output directory for rendered manifests (default: ./output)
  --repo <url>          Chart repository URL (for OCI or direct URLs)
  --username <user>     Username for chart repository (optional)
  --password <pass>     Password for chart repository (optional)

Validate Values:
  $(basename "$0") validate --chart <chart> --values <file> [options]
  --chart <chart>       Chart name or path
  --values <file>       Values file to validate
  --strict              Enable strict validation (optional)

Show Values:
  $(basename "$0") show-values --chart <chart> [options]
  --chart <chart>       Chart name or path
  --values <file>       Values file(s) to merge (optional)
  --version <version>   Chart version (optional)

Template:
  $(basename "$0") template --chart <chart> [options]
  Same options as 'render' command

Diff:
  $(basename "$0") diff --chart <chart> --values-a <file> --values-b <file>
  --chart <chart>       Chart name or path
  --values-a <file>     First values file
  --values-b <file>     Second values file

Examples:
  # Add a traditional Helm repository
  $(basename "$0") add-repo --name bitnami --url https://charts.bitnami.com/bitnami

  # Add an OCI registry with authentication
  $(basename "$0") add-repo --name myregistry --url oci://registry.example.com/charts \\
  --username myuser --password-stdin

  # Render a chart from a repository
  $(basename "$0") render --chart bitnami/nginx --values values.yaml --namespace prod

  # Render a chart from an OCI registry
  $(basename "$0") render --chart oci://registry.example.com/charts/myapp \\
  --values values.yaml --version 1.2.3

  # Render with multiple values files and overrides
  $(basename "$0") render --chart ./my-chart --values base.yaml --values prod.yaml \\
  --set image.tag=v1.2.3 --set replicas=3

  # Show all values (default + custom)
  $(basename "$0") show-values --chart bitnami/nginx --values my-values.yaml

  # Validate values file
  $(basename "$0") validate --chart ./my-chart --values values.yaml --strict

  # Compare two values files
  $(basename "$0") diff --chart bitnami/nginx --values-a dev.yaml --values-b prod.yaml

Environment Variables:
  HELM_REGISTRY_USERNAME    Default username for OCI registries
  HELM_REGISTRY_PASSWORD    Default password for OCI registries

EOF
  exit 0
}

# Check if helm is installed
check_helm() {
  if ! command -v helm &>/dev/null; then
    error "helm is not installed. Please install helm first: https://helm.sh/docs/intro/install/"
  fi
}

# Add a Helm repository
add_repo() {
  local name=""
  local url=""
  local username=""
  local password=""
  local password_stdin=false
  local insecure=false
  local force_update=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --name)
        name="$2"
        shift 2
        ;;
      --url)
        url="$2"
        shift 2
        ;;
      --username)
        username="$2"
        shift 2
        ;;
      --password)
        password="$2"
        shift 2
        ;;
      --password-stdin)
        password_stdin=true
        shift
        ;;
      --insecure-skip-tls)
        insecure=true
        shift
        ;;
      --force-update)
        force_update=true
        shift
        ;;
      *) error "Unknown option: $1" ;;
    esac
  done

  [[ -z "$name" ]] && error "Repository name is required (--name)"
  [[ -z "$url" ]] && error "Repository URL is required (--url)"

  # Read password from stdin if requested
  if [[ "$password_stdin" == true ]]; then
    info "Reading password from stdin..."
    read -s password
  fi

  # Check if it's an OCI registry
  if [[ "$url" =~ ^oci:// ]]; then
    info "Detected OCI registry: $url"

    # For OCI, we use helm registry login
    if [[ -n "$username" ]]; then
      local registry_host="${url#oci://}"
      registry_host="${registry_host%%/*}"

      info "Logging into OCI registry: $registry_host"

      if [[ -n "$password" ]]; then
        echo "$password" | helm registry login "$registry_host" --username "$username" --password-stdin
      else
        helm registry login "$registry_host" --username "$username"
      fi

      success "Logged into OCI registry: $registry_host"
    fi
  else
    # Traditional Helm repository
    info "Adding traditional Helm repository: $name"

    local helm_cmd="helm repo add $name $url"

    if [[ -n "$username" ]]; then
      helm_cmd="$helm_cmd --username $username"
    fi

    if [[ -n "$password" ]]; then
      helm_cmd="$helm_cmd --password $password"
    fi

    if [[ "$insecure" == true ]]; then
      helm_cmd="$helm_cmd --insecure-skip-tls-verify"
    fi

    if [[ "$force_update" == true ]]; then
      helm_cmd="$helm_cmd --force-update"
    fi

    eval "$helm_cmd"
    success "Added repository: $name"

    info "Updating repository..."
    helm repo update "$name"
    success "Repository updated"
  fi
}

# Render a Helm chart
render_chart() {
  local chart=""
  local namespace="default"
  local release="test-release"
  local values_files=()
  local set_values=()
  local version=""
  local output_dir="./output"
  local repo_url=""
  local username=""
  local password=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --chart)
        chart="$2"
        shift 2
        ;;
      --namespace)
        namespace="$2"
        shift 2
        ;;
      --release)
        release="$2"
        shift 2
        ;;
      --values)
        values_files+=("$2")
        shift 2
        ;;
      --set)
        set_values+=("$2")
        shift 2
        ;;
      --version)
        version="$2"
        shift 2
        ;;
      --output)
        output_dir="$2"
        shift 2
        ;;
      --repo)
        repo_url="$2"
        shift 2
        ;;
      --username)
        username="$2"
        shift 2
        ;;
      --password)
        password="$2"
        shift 2
        ;;
      *) error "Unknown option: $1" ;;
    esac
  done

  [[ -z "$chart" ]] && error "Chart is required (--chart)"

  # Handle OCI authentication if needed
  if [[ "$chart" =~ ^oci:// ]] && [[ -n "$username" ]]; then
    local registry_host="${chart#oci://}"
    registry_host="${registry_host%%/*}"
    info "Logging into OCI registry: $registry_host"
    echo "$password" | helm registry login "$registry_host" --username "$username" --password-stdin
  fi

  # Build helm template command
  local helm_cmd="helm template $release $chart --namespace $namespace"

  # Add values files
  for values_file in "${values_files[@]}"; do
    [[ ! -f "$values_file" ]] && error "Values file not found: $values_file"
    helm_cmd="$helm_cmd --values $values_file"
  done

  # Add set values
  for set_value in "${set_values[@]}"; do
    helm_cmd="$helm_cmd --set $set_value"
  done

  # Add version if specified
  if [[ -n "$version" ]]; then
    helm_cmd="$helm_cmd --version $version"
  fi

  # Add repo URL if specified
  if [[ -n "$repo_url" ]]; then
    helm_cmd="$helm_cmd --repo $repo_url"
  fi

  # Add username/password if specified
  if [[ -n "$username" ]]; then
    helm_cmd="$helm_cmd --username $username"
  fi
  if [[ -n "$password" ]]; then
    helm_cmd="$helm_cmd --password $password"
  fi

  # Create output directory
  mkdir -p "$output_dir"

  header "Rendering Helm Chart"
  info "Chart: $chart"
  info "Release: $release"
  info "Namespace: $namespace"
  [[ -n "$version" ]] && info "Version: $version"
  [[ ${#values_files[@]} -gt 0 ]] && info "Values files: ${values_files[*]}"
  [[ ${#set_values[@]} -gt 0 ]] && info "Set values: ${set_values[*]}"
  info "Output directory: $output_dir"
  echo ""

  # Render the chart
  info "Rendering chart..."
  local rendered_output
  rendered_output=$(eval "$helm_cmd")

  # Save full output
  echo "$rendered_output" >"$output_dir/all-manifests.yaml"
  success "Saved all manifests to: $output_dir/all-manifests.yaml"

  # Split by resource kind
  info "Splitting manifests by kind..."
  echo "$rendered_output" | awk '
    /^---$/ {
      if (filename != "") close(filename)
      kind = ""
      name = ""
      next
    }
    /^kind: / { kind = $2 }
    /^  name: / { name = $2 }
    {
      if (kind != "" && name != "") {
        filename = sprintf("'"$output_dir"'/%s-%s.yaml", kind, name)
        print >filename
      }
    }
  '

  # List generated files
  local file_count
  file_count=$(find "$output_dir" -type f -name "*.yaml" | wc -l)
  success "Generated $file_count manifest file(s) in $output_dir/"
  echo ""

  # Display summary
  header "Resource Summary"
  echo "$rendered_output" | grep -E "^kind:" | sort | uniq -c | while read -r count kind; do
    echo -e "  ${GREEN}$count${NC}x $kind"
  done
  echo ""

  # Validate syntax
  info "Validating YAML syntax..."
  if command -v kubectl &>/dev/null; then
    if kubectl apply --dry-run=client -f "$output_dir/all-manifests.yaml" &>/dev/null; then
      success "YAML syntax is valid"
    else
      warning "YAML validation found issues. Run: kubectl apply --dry-run=client -f $output_dir/all-manifests.yaml"
    fi
  else
    warning "kubectl not found. Skipping YAML validation."
  fi

  success "Chart rendering complete!"
}

# Validate chart values
validate_values() {
  local chart=""
  local values_file=""
  local strict=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --chart)
        chart="$2"
        shift 2
        ;;
      --values)
        values_file="$2"
        shift 2
        ;;
      --strict)
        strict=true
        shift
        ;;
      *) error "Unknown option: $1" ;;
    esac
  done

  [[ -z "$chart" ]] && error "Chart is required (--chart)"
  [[ -z "$values_file" ]] && error "Values file is required (--values)"
  [[ ! -f "$values_file" ]] && error "Values file not found: $values_file"

  header "Validating Values File"
  info "Chart: $chart"
  info "Values file: $values_file"
  echo ""

  # Try to render with lint
  info "Running helm lint..."
  local lint_cmd="helm lint $chart --values $values_file"

  if [[ "$strict" == true ]]; then
    lint_cmd="$lint_cmd --strict"
  fi

  if eval "$lint_cmd"; then
    success "Validation passed!"
  else
    error "Validation failed. Check the output above for details."
  fi

  # Try template to catch rendering errors
  info "Testing template rendering..."
  if helm template test-release "$chart" --values "$values_file" >/dev/null 2>&1; then
    success "Template rendering successful!"
  else
    warning "Template rendering encountered issues. Run:"
    echo "  helm template test-release $chart --values $values_file"
  fi
}

# Show chart values
show_values() {
  local chart=""
  local values_files=()
  local version=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --chart)
        chart="$2"
        shift 2
        ;;
      --values)
        values_files+=("$2")
        shift 2
        ;;
      --version)
        version="$2"
        shift 2
        ;;
      *) error "Unknown option: $1" ;;
    esac
  done

  [[ -z "$chart" ]] && error "Chart is required (--chart)"

  header "Helm Chart Values"
  info "Chart: $chart"
  [[ -n "$version" ]] && info "Version: $version"
  echo ""

  # Show default values
  echo -e "${CYAN}Default Values:${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  local show_cmd="helm show values $chart"
  [[ -n "$version" ]] && show_cmd="$show_cmd --version $version"
  eval "$show_cmd"
  echo ""

  # If values files provided, show computed values
  if [[ ${#values_files[@]} -gt 0 ]]; then
    echo -e "${CYAN}Computed Values (with overrides):${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local template_cmd="helm template test-release $chart"
    for values_file in "${values_files[@]}"; do
      [[ ! -f "$values_file" ]] && error "Values file not found: $values_file"
      template_cmd="$template_cmd --values $values_file"
    done
    [[ -n "$version" ]] && template_cmd="$template_cmd --version $version"
    template_cmd="$template_cmd --show-only templates/NOTES.txt 2>/dev/null || true"

    # Show merged values
    eval "$template_cmd"
  fi
}

# Diff two values files
diff_values() {
  local chart=""
  local values_a=""
  local values_b=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      --chart)
        chart="$2"
        shift 2
        ;;
      --values-a)
        values_a="$2"
        shift 2
        ;;
      --values-b)
        values_b="$2"
        shift 2
        ;;
      *) error "Unknown option: $1" ;;
    esac
  done

  [[ -z "$chart" ]] && error "Chart is required (--chart)"
  [[ -z "$values_a" ]] && error "First values file is required (--values-a)"
  [[ -z "$values_b" ]] && error "Second values file is required (--values-b)"
  [[ ! -f "$values_a" ]] && error "Values file not found: $values_a"
  [[ ! -f "$values_b" ]] && error "Values file not found: $values_b"

  header "Comparing Values Files"
  info "Chart: $chart"
  info "File A: $values_a"
  info "File B: $values_b"
  echo ""

  # Create temporary directory for rendered output
  local temp_dir
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  # Render with first values file
  info "Rendering with $values_a..."
  helm template test-release "$chart" --values "$values_a" >"$temp_dir/rendered-a.yaml"

  # Render with second values file
  info "Rendering with $values_b..."
  helm template test-release "$chart" --values "$values_b" >"$temp_dir/rendered-b.yaml"

  # Show diff
  echo -e "${CYAN}Differences in rendered output:${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if command -v diff &>/dev/null; then
    if diff -u "$temp_dir/rendered-a.yaml" "$temp_dir/rendered-b.yaml"; then
      success "No differences found!"
    fi
  else
    error "diff command not found"
  fi
}

# Main command dispatcher
main() {
  check_helm

  if [[ $# -eq 0 ]]; then
    usage
  fi

  local command=$1
  shift

  case $command in
    add-repo)
      add_repo "$@"
      ;;
    render | template)
      render_chart "$@"
      ;;
    validate)
      validate_values "$@"
      ;;
    show-values)
      show_values "$@"
      ;;
    diff)
      diff_values "$@"
      ;;
    help | --help | -h)
      usage
      ;;
    *)
      error "Unknown command: $command. Run '$(basename "$0") help' for usage."
      ;;
  esac
}

main "$@"
