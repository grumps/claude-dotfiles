# Terraform Style Guide

This document defines Terraform coding standards and tooling practices for projects using Claude dotfiles. All Terraform code should follow these guidelines for consistency, maintainability, and security.

## Philosophy

- **Infrastructure as Code** - Treat infrastructure code with the same rigor as application code
- **Explicit over implicit** - Be clear about resource dependencies and configurations
- **Security first** - Never commit secrets, use least privilege, enable encryption by default
- **Modular design** - Break complex infrastructure into reusable modules
- **State management** - Protect and version state files appropriately
- **Documentation** - Document architecture decisions and non-obvious configurations

### Core Principles

1. **No hardcoded secrets** - Use variables, data sources, or secret managers
2. **Use modules** - DRY principle applies to infrastructure
3. **Enable encryption** - Always encrypt at rest and in transit
4. **Tag everything** - Consistent tagging for cost tracking and organization
5. **Validate inputs** - Use variable validation rules
6. **Plan before apply** - Always review plans before applying changes
7. **Format consistently** - Use `terraform fmt` on all files
8. **Layered architecture** - Favor separation of concerns across logical layers
9. **Local modules first** - Use local modules until it doesn't make sense
10. **Avoid local-exec** - Never use local-exec provisioners (極力避ける)

---

## Architecture Principles

### Layered Architecture

Favor a **layered architecture** that separates concerns and promotes maintainability:

```text
terraform/
├── layers/
│   ├── 1-foundation/        # VPC, networking, base security
│   │   ├── main.tf
│   │   ├── vpc.tf
│   │   ├── subnets.tf
│   │   └── security-groups.tf
│   ├── 2-data/              # Databases, caches, storage
│   │   ├── main.tf
│   │   ├── rds.tf
│   │   └── s3.tf
│   ├── 3-compute/           # EC2, ECS, Lambda
│   │   ├── main.tf
│   │   └── instances.tf
│   └── 4-application/       # Application-specific resources
│       ├── main.tf
│       └── load-balancers.tf
└── modules/                 # Reusable local modules
    ├── vpc/
    ├── database/
    └── compute/
```

**Benefits:**

- **Clear dependencies** - Lower layers can't depend on higher layers
- **Incremental deployment** - Apply layers sequentially (foundation → data → compute → application)
- **Easier troubleshooting** - Issues isolated to specific layers
- **Team collaboration** - Different teams can own different layers

**Example layer progression:**

```bash
# Apply in order
cd layers/1-foundation && terraform apply
cd layers/2-data && terraform apply
cd layers/3-compute && terraform apply
cd layers/4-application && terraform apply
```

---

## File Organization

### Directory Structure

```text
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/
│   └── database/
├── .terraform-version
├── .tflint.hcl
└── .pre-commit-config.yaml
```

### File Naming Conventions

- **main.tf** - Primary resource definitions
- **variables.tf** - Input variable declarations
- **outputs.tf** - Output value declarations
- **backend.tf** - Backend configuration (optional, can be in main.tf)
- **versions.tf** - Terraform and provider version constraints
- **locals.tf** - Local value definitions (when many locals exist)
- **data.tf** - Data source definitions (when many data sources exist)

---

## Formatting & Style

### Line Length

- **Maximum line length:** 120 characters
- **Use terraform fmt:** Run on all files before committing

### Naming Conventions

- **Resources:** `snake_case` with descriptive names
- **Variables:** `snake_case` with clear, descriptive names
- **Outputs:** `snake_case` describing what is being output
- **Modules:** `kebab-case` for directory names

```hcl
# ✅ Good
resource "aws_instance" "web_server" {
  ami           = var.web_server_ami
  instance_type = var.web_server_instance_type
}

variable "web_server_ami" {
  description = "AMI ID for web server instances"
  type        = string
}

output "web_server_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

# ❌ Avoid
resource "aws_instance" "webServer" {  # camelCase
  ami           = var.ami1             # Unclear name
  instance_type = "t3.micro"           # Hardcoded value
}

variable "ami" {                       # Too vague
  type = string
}

output "ip" {                          # Too brief
  value = aws_instance.webServer.public_ip
}
```

### Comments

- **Module-level:** Include description at top of main.tf
- **Resource-level:** Comment complex resources or non-obvious configurations
- **Inline:** Explain business logic or security requirements

```hcl
# ✅ Good
# Enable encryption at rest for compliance with SOC2 requirements
# KMS key rotation is enabled automatically (90 days)
resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id       = aws_kms_key.db.arn

  # Use Multi-AZ for production workloads
  multi_az = var.environment == "prod" ? true : false
}

# ❌ Avoid
# Create database
resource "aws_db_instance" "main" {
  storage_encrypted = true  # Encrypt
  kms_key_id       = aws_kms_key.db.arn
  multi_az         = var.environment == "prod" ? true : false
}
```

---

## Resource Configuration

### Resource Naming

- **Use descriptive names** that indicate the resource's purpose
- **Include environment/purpose** in resource names when helpful
- **Avoid redundant prefixes** (resource type is already clear)

```hcl
# ✅ Good
resource "aws_s3_bucket" "application_logs" {
  bucket = "${var.project_name}-${var.environment}-logs"
}

resource "aws_security_group" "web_server" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web servers"
}

# ❌ Avoid
resource "aws_s3_bucket" "bucket1" {
  bucket = "my-logs"  # Not unique, will conflict
}

resource "aws_security_group" "sg_web_server" {
  name = "web-sg"  # Missing project/environment context
}
```

### Resource Blocks

- **Order attributes logically:**
  1. Required attributes
  2. Optional attributes
  3. Lifecycle blocks
  4. Tags (last)

- **One resource per block** (no count/for_each sprawl)

```hcl
# ✅ Good
resource "aws_instance" "web_server" {
  # Required attributes first
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Optional attributes
  monitoring              = true
  associate_public_ip_address = false

  # Security
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile   = aws_iam_instance_profile.web_server.name

  # Storage configuration
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  # Lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }

  # Tags always last
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-web"
      Role = "web-server"
    }
  )
}
```

---

## Variables

### Variable Declarations

- **Always include description** - Explain the variable's purpose
- **Specify type** - Use appropriate type constraints
- **Use validation** - Add validation rules for critical variables
- **Provide defaults** - When sensible defaults exist

```hcl
# ✅ Good
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

# ❌ Avoid
variable "env" {           # Too brief, no description
  type = string
}

variable "count" {         # No validation
  type = number
}

variable "tags" {          # Unclear what tags are for
  default = {}
}
```

### Variable Types

Use specific types for better validation:

```hcl
# String
variable "region" {
  type = string
}

# Number
variable "port" {
  type = number
}

# Boolean
variable "enabled" {
  type = bool
}

# List
variable "availability_zones" {
  type = list(string)
}

# Map
variable "instance_types" {
  type = map(string)
}

# Object (structured)
variable "database_config" {
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
    allocated_storage = number
  })
}
```

---

## Outputs

### Output Declarations

- **Include descriptions** - Explain what is being output and why
- **Mark sensitive data** - Use `sensitive = true` for secrets
- **Output useful information** - IDs, ARNs, endpoints users need

```hcl
# ✅ Good
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "database_endpoint" {
  description = "Connection endpoint for the database"
  value       = aws_db_instance.main.endpoint
}

output "database_password" {
  description = "Master password for the database"
  value       = random_password.db_password.result
  sensitive   = true
}

output "s3_bucket_names" {
  description = "Names of all S3 buckets created"
  value = {
    logs    = aws_s3_bucket.logs.id
    data    = aws_s3_bucket.data.id
    backups = aws_s3_bucket.backups.id
  }
}

# ❌ Avoid
output "id" {              # Unclear what this is
  value = aws_vpc.main.id
}

output "password" {        # Sensitive but not marked
  value = random_password.db_password.result
}
```

---

## Modules

### Module Strategy

**Prefer local modules** over remote/registry modules until it doesn't make sense:

- ✅ **Start with local modules** - Keep modules in your repository (`../../modules/vpc`)
- ✅ **Control and customization** - Easy to modify and adapt to your needs
- ✅ **Version with your code** - Modules evolve with your infrastructure
- ✅ **Faster iteration** - No need to publish/version separately
- ⚠️ **Consider registry modules** when:
  - Module is stable and shared across many projects
  - You need strict versioning for compliance
  - Module is maintained by a separate team
  - Using well-established community modules (e.g., AWS VPC module)

```hcl
# ✅ Good - local module (preferred starting point)
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

# ✅ Also acceptable - registry module for stable, shared resources
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
}

# ❌ Avoid - remote git sources (hard to version and track)
module "vpc" {
  source = "git::https://github.com/example/terraform-modules.git//vpc?ref=main"
}
```

### Module Structure

Every module should have:

- **main.tf** - Resource definitions
- **variables.tf** - Input variables
- **outputs.tf** - Output values
- **README.md** - Module documentation
- **versions.tf** - Version constraints (optional)

### Module Usage

```hcl
# ✅ Good
module "vpc" {
  source  = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  cidr_block   = var.vpc_cidr

  availability_zones = var.availability_zones

  common_tags = var.common_tags
}

# Use module outputs
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.vpc.default_security_group_id]
}
```

### Module Documentation

Include in module README.md:

```markdown
# VPC Module

Creates a VPC with public and private subnets across multiple availability zones.

## Features

- Multi-AZ deployment
- Public and private subnets
- NAT gateways for private subnet internet access
- VPC Flow Logs for network monitoring

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "my-project"
  environment        = "prod"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | - | yes |
| environment | Environment name | string | - | yes |
| cidr_block | CIDR block for VPC | string | - | yes |
| availability_zones | List of AZs | list(string) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |

```text

```text
---
```

## Security Best Practices

### Never Commit Secrets

```hcl
# ❌ NEVER do this
resource "aws_db_instance" "main" {
  password = "supersecretpassword123"  # NEVER hardcode
}

# ✅ Use random passwords
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_db_instance" "main" {
  password = random_password.db_password.result
}

# ✅ Or reference from secret manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_id
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### Enable Encryption

```hcl
# ✅ Good - encrypt everything by default
resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id       = aws_kms_key.db.arn
}

# Enable encryption in transit
resource "aws_db_instance" "main" {
  # ... other config

  # Require SSL connections
  parameter_group_name = aws_db_parameter_group.require_ssl.name
}
```

### Least Privilege IAM

```hcl
# ✅ Good - specific permissions
resource "aws_iam_policy" "s3_read_only" {
  name        = "${var.project_name}-s3-read-only"
  description = "Allow read-only access to specific S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data.arn,
          "${aws_s3_bucket.data.arn}/*"
        ]
      }
    ]
  })
}

# ❌ Avoid - overly broad permissions
resource "aws_iam_policy" "admin" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}
```

---

## State Management

### Backend Configuration

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "myproject-terraform-state"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-west-2:ACCOUNT:key/KEY-ID"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### State Best Practices

1. **Enable encryption** - Always encrypt state files
2. **Enable versioning** - Use S3 versioning for state bucket
3. **Use state locking** - Prevent concurrent modifications
4. **Separate state files** - Per environment/component
5. **Never commit state** - Add to `.gitignore`

```gitignore
# .gitignore
.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfvars  # If contains sensitive data
```

---

## Tagging Strategy

### Provider-Level Default Tags (Preferred)

**Define tags at the provider level** using `default_tags` to automatically apply them to all resources:

```hcl
# ✅ Good - provider-level default tags (PREFERRED)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.team_name
      CostCenter  = var.cost_center
    }
  }
}

# Resources automatically inherit default tags
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Only add resource-specific tags
  tags = {
    Name = "${var.project_name}-${var.environment}-web"
    Role = "web-server"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"

  # Only add resource-specific tags
  tags = {
    Name    = "application-data"
    Purpose = "data-storage"
  }
}
```

**Benefits of provider-level tags:**

- **DRY principle** - Define common tags once
- **Consistency** - All resources automatically tagged
- **Less boilerplate** - No need for `merge()` on every resource
- **Easier maintenance** - Update tags in one place
- **Reduced errors** - Can't forget to tag a resource

### Alternative: Local Variables (When Provider Tags Not Available)

If your provider doesn't support `default_tags`, use local variables:

```hcl
# ⚠️ Acceptable fallback - local variable approach
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.team_name
    CostCenter  = var.cost_center
  }
}

resource "aws_instance" "web" {
  # ... other config

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-web"
      Role = "web-server"
    }
  )
}
```

### Required Tags

Every resource should have these tags (via provider defaults or locals):

- **Project** - Project name
- **Environment** - Environment (dev, staging, prod)
- **ManagedBy** - Always "terraform"
- **Owner** - Team or individual responsible
- **CostCenter** - For cost allocation and tracking

---

## Tooling

### Required Tools

- **terraform** - Infrastructure provisioning
- **terraform-docs** - Generate documentation from Terraform modules
- **tflint** - Linter for Terraform
- **tfsec** - Security scanner for Terraform
- **checkov** - Policy-as-code scanner (optional but recommended)

### Tool Configuration

#### .tflint.hcl

```hcl
plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}
```

#### .terraform-version

```text
1.6.0
```

### Pre-commit Hooks

Install pre-commit hooks to run checks automatically:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_tfsec
```

---

## Code Review Checklist

Before submitting Terraform code, verify:

**Architecture & Design:**

- [ ] Layered architecture followed (foundation → data → compute → application)
- [ ] Using local modules (unless registry modules are justified)
- [ ] Tags defined at provider level using `default_tags`
- [ ] No `local-exec` or `remote-exec` provisioners used

**Code Quality:**

- [ ] All files formatted with `terraform fmt`
- [ ] `terraform validate` passes
- [ ] `tflint` passes with no errors
- [ ] `tfsec` passes with no high/critical issues

**Variables & Outputs:**

- [ ] All variables have descriptions
- [ ] All variables have appropriate types
- [ ] Critical variables have validation rules
- [ ] All outputs have descriptions
- [ ] Sensitive outputs marked as `sensitive = true`

**Security:**

- [ ] No hardcoded secrets or credentials
- [ ] Encryption enabled for data at rest
- [ ] Encryption enabled for data in transit
- [ ] IAM policies follow least privilege principle
- [ ] State backend configured with encryption and locking

**Documentation & Review:**

- [ ] All resources have appropriate tags (inherited from provider or explicit)
- [ ] Module README.md updated (if applicable)
- [ ] `terraform plan` reviewed and approved

---

## Common Patterns

### Conditional Resources

```hcl
# Create resource only in production
resource "aws_cloudwatch_log_group" "detailed" {
  count = var.environment == "prod" ? 1 : 0

  name              = "/aws/application/${var.project_name}"
  retention_in_days = 90
}

# Using for_each for multiple similar resources
resource "aws_s3_bucket" "data" {
  for_each = toset(var.data_bucket_names)

  bucket = "${var.project_name}-${each.key}"

  tags = merge(
    local.common_tags,
    {
      Name   = each.key
      Purpose = "data-storage"
    }
  )
}
```

### Dynamic Blocks

```hcl
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

---

## Anti-Patterns

### ❌ Never Use local-exec Provisioners

**Avoid `local-exec` provisioners like the plague.** They break Terraform's declarative model and create hidden dependencies.

```hcl
# ❌ NEVER DO THIS
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, playbook.yml"
  }
}

# ❌ NEVER DO THIS EITHER
resource "null_resource" "configure_server" {
  provisioner "local-exec" {
    command = "ssh user@${aws_instance.web.public_ip} 'sudo apt-get update'"
  }
}
```

**Why avoid local-exec:**

- **Not idempotent** - Commands may fail on re-runs
- **Hidden dependencies** - External tools must be installed (ansible, aws-cli, etc.)
- **State drift** - No way to track what actually happened
- **Debugging nightmare** - Failures are hard to troubleshoot
- **CI/CD friction** - Requires additional tools in pipeline
- **Security risks** - Running arbitrary commands is dangerous

**Better alternatives:**

```hcl
# ✅ Use user_data for instance configuration
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    app_version = var.app_version
  })
}

# ✅ Use separate configuration management tools
# Run Ansible/Chef/Puppet OUTSIDE of Terraform
# Terraform creates infrastructure, other tools configure it

# ✅ Use cloud-native solutions
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # Use Systems Manager for configuration
  iam_instance_profile = aws_iam_instance_profile.ssm.name
}

resource "aws_ssm_association" "web_config" {
  name = aws_ssm_document.web_config.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.web.id]
  }
}

# ✅ Use custom AMIs (Packer) with baked-in configuration
data "aws_ami" "web" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["web-server-${var.app_version}"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.web.id
  instance_type = var.instance_type
}
```

### Other Anti-Patterns to Avoid

#### ❌ Hardcoded values

```hcl
# Bad
resource "aws_instance" "web" {
  instance_type = "t3.micro"
  subnet_id     = "subnet-12345678"
}

# Good
resource "aws_instance" "web" {
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
}
```

#### ❌ Missing lifecycle blocks for critical resources

```hcl
# Bad - instance replacement causes downtime
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}

# Good - create new before destroying old
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}
```

**❌ Over-using count instead of for_each**

```hcl
# Bad - reordering list causes resource recreation
resource "aws_instance" "web" {
  count = length(var.subnet_ids)

  subnet_id = var.subnet_ids[count.index]
}

# Good - use for_each with stable keys
resource "aws_instance" "web" {
  for_each = toset(var.subnet_ids)

  subnet_id = each.value
}
```

---

## Testing

### Pre-deployment Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Security scanning
tfsec .

# Linting
tflint --recursive

# Plan review
terraform plan -out=tfplan
terraform show -json tfplan | jq
```

### Post-deployment Validation

- Review outputs match expected values
- Verify resources created in correct region/VPC
- Check tags applied correctly
- Validate security groups and IAM policies
- Test connectivity and access
- Review CloudWatch logs for errors

---

## When in Doubt

1. **Check provider documentation** - Terraform provider docs are authoritative
2. **Run the tools** - `terraform fmt`, `tflint`, `tfsec` catch most issues
3. **Review the plan** - Always review `terraform plan` output before applying
4. **Ask questions** - Unclear requirements should be clarified before provisioning
5. **Prioritize security** - When choice between convenient and secure, choose secure

---

**Last Updated:** 2025-11-18
**Maintained by:** Project maintainers
