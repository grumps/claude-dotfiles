# Docker Base Container (CI/CD)

This directory contains a Docker base container for **CI/CD pipelines only**. It includes all the tools needed for automated validation, testing, and deployment workflows.

**Important**: This container is designed for CI/CD environments (GitHub Actions, GitLab CI, etc.), not for local development. For local development, install tools directly on your machine using the installation instructions in the main README.

## Base Image

The container is built on `public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim`, which provides a Debian Bookworm slim base with the `install_deb` script for package installation.

The Dockerfile uses multi-stage builds to copy binaries from official containers, ensuring we get verified, official binaries without relying on install scripts. This approach is more reliable and faster than downloading/executing installation scripts.

## Included Tools

### Core Utilities
- **git** - Version control
- **curl** / **wget** - File downloading
- **jq** - JSON processing
- **ca-certificates** / **gnupg** - Security and signing
- **libnotify-bin** - Desktop notifications
- **less** / **vim** - Text viewing and editing

### Shell Development
- **shellcheck** - Shell script linting
- **shfmt** (v3.8.0) - Shell script formatting

### Command Runner
- **just** - Task runner and command orchestration

### Kubernetes Tools
- **helm** - Kubernetes package manager (from alpine/helm)
- **kubectl** - Kubernetes CLI (from dl.k8s.io)
- **kustomize** - Kubernetes configuration management
- **yamllint** - YAML validation

### Go Development
- **golangci-lint** - Go linting (from golangci/golangci-lint)

### Python Development
- **python3-pip** - Python package installer
- **uv** - Fast Python package installer and resolver
- **ruff** - Fast Python linter (installed via uv)
- **yamllint** - YAML validation (installed via uv)

### Terraform Tools
- **terraform** - Infrastructure as Code (from HashiCorp apt repo)
- **tflint** - Terraform linting (from ghcr.io/terraform-linters/tflint)
- **tfsec** - Terraform security scanner (from aquasec/tfsec)

## Using Pre-Built Images (CI/CD Only)

Pre-built images are automatically published to GitHub Container Registry (ghcr.io) for use in CI/CD pipelines:

- **On push to main** - Tagged as `latest`
- **On version tags** (v1.2.3) - Tagged with semver versions
- **Platform** - Built for linux/amd64 (ARM64 support pending base image compatibility)
- **Signed** - Includes build provenance attestation

### Pull the Latest Image

```bash
docker pull ghcr.io/grumps/claude-dotfiles:latest
```

### Available Tags

- `latest` - Latest build from the main branch
- `v1.2.3` - Specific version tags (semver)
- `1.2` - Major.minor version tags
- `1` - Major version tags
- `sha-abc123` - SHA-tagged builds from main branch

### Using the Pre-Built Image

**In CI/CD pipelines:**

```bash
# Pull the latest image (automated in CI/CD)
docker pull ghcr.io/grumps/claude-dotfiles:latest

# GitHub Actions example - see CI/CD Usage section below
```

**For local Dockerfile testing only:**
# Interactive shell
docker run -it --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest

# Run validation
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest just validate

# Run specific commands
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest just lint
```

## Building the Container Locally

**Note**: Local builds are only needed for testing changes to the Dockerfile itself. For normal development, install tools directly on your machine.

If you need to test Dockerfile changes locally:

```bash
docker build -t claude-dotfiles-base:latest .
```

### Multi-Stage Build

The Dockerfile uses multi-stage builds to copy binaries from official containers where possible:
- **helm** - Copied from `alpine/helm:latest`
- **golangci-lint** - Copied from `golangci/golangci-lint:latest`
- **tflint** - Copied from `ghcr.io/terraform-linters/tflint:latest`
- **tfsec** - Copied from `aquasec/tfsec:latest`
- **kubectl** - Downloaded from official Kubernetes releases (dl.k8s.io)

This approach ensures:
- Official, verified binaries from maintainers
- Reduced reliance on installation scripts that could fail
- Faster builds with better layer caching
- Automatic architecture support from source containers

## CI/CD Usage

This container is designed for CI/CD pipelines. Use the pre-built image for fast, consistent builds:

```yaml
# GitHub Actions example
jobs:
  validate:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/grumps/claude-dotfiles:latest
    steps:
      - uses: actions/checkout@v4
      - name: Run validation
        run: just validate
```

```yaml
# GitLab CI example
validate:
  image: ghcr.io/grumps/claude-dotfiles:latest
  script:
    - just validate
```

## Extending the Container

To add project-specific tools, create a new Dockerfile that extends the pre-built image:

```dockerfile
FROM ghcr.io/grumps/claude-dotfiles:latest

# Add your custom tools
RUN install_deb nodejs npm

# Install project dependencies
COPY package.json .
RUN npm install

WORKDIR /workspace
```

## Tool Verification

The container includes a verification step during build that checks all tools are installed correctly. If the build completes successfully, all tools are verified and ready to use.

## Volume Mounts

When running the container, mount your project directory to `/workspace`:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.gitconfig:/root/.gitconfig:ro \
  -v ~/.ssh:/root/.ssh:ro \
  claude-dotfiles-base:latest
```

This allows you to:
- Work with your project files in `/workspace`
- Use your git configuration
- Access SSH keys for git operations

## Caching

To optimize build times, the Dockerfile:
- Cleans up apt lists after installations
- Uses `--no-cache-dir` for pip installations
- Downloads and installs tools in logical layers

## Troubleshooting

### Tool Not Found

If a tool is not found, verify the installation in the Dockerfile and rebuild:

```bash
docker build --no-cache -t claude-dotfiles-base:latest .
```

### Permission Issues

If you encounter permission issues with mounted volumes, you may need to run the container with your user ID:

```bash
docker run -it --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):/workspace \
  claude-dotfiles-base:latest
```

### Build Failures

If the build fails during tool installation:
1. Check the base image is accessible: `docker pull public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim`
2. Verify network connectivity for downloading tools
3. Check the specific error message in the build output

## Publishing Workflow

The container image is automatically built and published using GitHub Actions (`.github/workflows/docker-publish.yml`).

### Automatic Publishing

The workflow is triggered on:
- **Push to main/master** - Builds and publishes with `latest` tag
- **Version tags** (v1.2.3) - Builds and publishes with semver tags
- **Pull requests** - Builds only (does not publish)

### Creating a Release

To publish a new version:

1. Create and push a version tag:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```

2. The workflow will automatically:
   - Build the image for linux/amd64 platform
   - Tag with `v1.2.3`, `1.2`, and `1`
   - Push to GitHub Container Registry
   - Generate build provenance attestation

### Workflow Features

- **Platform support** - Currently linux/amd64 (ARM64 pending base image compatibility)
- **Layer caching** - Uses GitHub Actions cache for faster builds
- **Security** - Generates and attaches build provenance
- **Metadata** - Includes OCI labels for version, description, and more
- **Efficient** - Only publishes on main branch and tags, not PRs

### ARM64 Support

ARM64 support is currently disabled due to base image compatibility issues. The base image `public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim` does not properly support ARM64 architecture. Once a compatible base image is available, ARM64 builds will be re-enabled.
