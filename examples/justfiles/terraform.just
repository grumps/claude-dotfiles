# Terraform-specific recipes

# Format Terraform files
tf-fmt:
  terraform fmt -recursive

# Validate Terraform configuration
tf-validate:
  terraform validate

# Run Terraform linter
tf-lint:
  #!/usr/bin/env bash
  if command -v tflint &> /dev/null; then
    tflint --recursive --config="$(git rev-parse --show-toplevel)/.tflint.hcl"
  else
    echo "⚠️  tflint not installed, skipping"
    echo "Install: https://github.com/terraform-linters/tflint"
  fi

# Run Terraform security scanner
tf-sec:
  #!/usr/bin/env bash
  if command -v tfsec &> /dev/null; then
    tfsec .
  else
    echo "⚠️  tfsec not installed, skipping"
    echo "Install: https://github.com/aquasecurity/tfsec"
  fi

# Run Checkov security scanner (optional but recommended)
tf-checkov:
  #!/usr/bin/env bash
  if command -v checkov &> /dev/null; then
    checkov -d .
  else
    echo "⚠️  checkov not installed, skipping"
    echo "Install: pip install checkov"
  fi

# Generate module documentation
tf-docs:
  #!/usr/bin/env bash
  if command -v terraform-docs &> /dev/null; then
    find . -type f -name "main.tf" -not -path "*/.terraform/*" | \
      xargs -I {} dirname {} | \
      xargs -I {} sh -c 'terraform-docs markdown table --output-file README.md {}'
  else
    echo "⚠️  terraform-docs not installed, skipping"
    echo "Install: https://terraform-docs.io/user-guide/installation/"
  fi

# Initialize Terraform (download providers and modules)
tf-init:
  terraform init

# Create Terraform execution plan
tf-plan:
  terraform plan -out=tfplan

# Apply Terraform changes
tf-apply:
  terraform apply tfplan

# Destroy Terraform-managed infrastructure (use with caution!)
tf-destroy:
  @echo "⚠️  WARNING: This will destroy all Terraform-managed infrastructure!"
  @echo "Press Ctrl+C to cancel, or Enter to continue..."
  @read
  terraform destroy

# Show current Terraform state
tf-show:
  terraform show

# List Terraform resources
tf-list:
  terraform state list

# Refresh Terraform state
tf-refresh:
  terraform refresh

# Run all Terraform checks (format, validate, lint, security)
tf-check: tf-fmt-check tf-validate tf-lint tf-sec

# Check if Terraform files are formatted (fails if not)
tf-fmt-check:
  terraform fmt -check -recursive

# Clean Terraform cache and state files (use with caution!)
tf-clean:
  @echo "⚠️  This will remove .terraform directories and lock files"
  @echo "Press Ctrl+C to cancel, or Enter to continue..."
  @read
  find . -type d -name ".terraform" -not -path "*/.git/*" -exec rm -rf {} +
  find . -type f -name ".terraform.lock.hcl" -not -path "*/.git/*" -delete
  @echo "✓ Terraform cache cleaned"
