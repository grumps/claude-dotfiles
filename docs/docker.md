# Docker Base Container

This directory contains a Docker base container that includes all the tools needed for the claude-dotfiles project.

## Base Image

The container is built on `public.ecr.aws/x2w2w0z4/base:v0.5.1-bookworm-slim`, which provides a Debian Bookworm slim base with the `install_deb` script for package installation.

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
- **helm** - Kubernetes package manager
- **kubectl** - Kubernetes CLI
- **kustomize** - Kubernetes configuration management
- **yamllint** - YAML validation

### Go Development
- **golangci-lint** (v1.55.2) - Go linting

### Python Development
- **python3-pip** - Python package installer
- **ruff** - Fast Python linter
- **yamllint** - YAML validation (via pip)

### Terraform Tools
- **terraform** - Infrastructure as Code
- **tflint** - Terraform linting
- **tfsec** - Terraform security scanner

## Using Pre-Built Images

Pre-built images are automatically published to GitHub Container Registry (ghcr.io) via GitHub Actions:

- **On push to main** - Tagged as `latest`
- **On version tags** (v1.2.3) - Tagged with semver versions
- **Multi-platform** - Built for linux/amd64 and linux/arm64
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

```bash
# Interactive shell
docker run -it --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest

# Run validation
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest just validate

# Run specific commands
docker run --rm -v $(pwd):/workspace ghcr.io/grumps/claude-dotfiles:latest just lint
```

## Building the Container Locally

If you need to build the container locally (for development or customization):

```bash
docker build -t claude-dotfiles-base:latest .
```

## CI/CD Usage

Use the pre-built image in your CI/CD pipelines for fast, consistent builds:

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
   - Build the image for amd64 and arm64 platforms
   - Tag with `v1.2.3`, `1.2`, and `1`
   - Push to GitHub Container Registry
   - Generate build provenance attestation

### Workflow Features

- **Multi-platform builds** - Supports linux/amd64 and linux/arm64
- **Layer caching** - Uses GitHub Actions cache for faster builds
- **Security** - Generates and attaches build provenance
- **Metadata** - Includes OCI labels for version, description, and more
- **Efficient** - Only publishes on main branch and tags, not PRs
