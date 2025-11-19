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

## Building the Container

```bash
docker build -t claude-dotfiles-base:latest .
```

## Using the Container

### Interactive Shell

```bash
docker run -it --rm -v $(pwd):/workspace claude-dotfiles-base:latest
```

### Running Commands

```bash
docker run --rm -v $(pwd):/workspace claude-dotfiles-base:latest just --list
```

### Running Validation

```bash
docker run --rm -v $(pwd):/workspace claude-dotfiles-base:latest just validate
```

## CI/CD Usage

You can use this container in your CI/CD pipelines:

```yaml
# GitHub Actions example
jobs:
  validate:
    runs-on: ubuntu-latest
    container:
      image: claude-dotfiles-base:latest
    steps:
      - uses: actions/checkout@v4
      - name: Run validation
        run: just validate
```

## Extending the Container

To add project-specific tools, create a new Dockerfile that extends this base:

```dockerfile
FROM claude-dotfiles-base:latest

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
