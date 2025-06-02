# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform-based Google Cloud Platform (GCP) landing zone implementation for a banking environment. It establishes the foundational infrastructure and organizational structure following enterprise best practices.

## Key Architecture Components

1. **Organization Structure**: Hierarchical folder structure with shared services, production, non-production, and sandbox environments
2. **Multi-Region Setup**: Primary region in africa-south1 with disaster recovery in europe-west2
3. **Network Architecture**: Hub-and-spoke VPC design with dedicated CIDRs for each environment
4. **Security Controls**: VPC Service Controls, CMEK encryption, and Security Command Center integration

## Common Development Commands

### Terraform Commands
```bash
# Initialize Terraform (required before any other operations)
terraform init

# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy infrastructure (use with caution)
terraform destroy
```

### Development Workflow
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and configure values
2. Run `terraform init` to initialize providers and backend
3. Use `terraform plan` to preview changes before applying
4. Apply changes with `terraform apply` after review

## Code Structure

- **main.tf**: Core infrastructure definitions including organization setup, shared services, and service account configuration
- **variables.tf**: All input variables with validation rules and defaults
- **modules/**: Reusable Terraform modules for organization and shared services components
- **terraform.tfvars.example**: Example configuration file with required variables

## Important Configuration

### Network CIDR Allocation
- Production ZA: 10.245.0.0/19
- Production LON: 10.245.32.0/19
- Non-prod ZA: 10.245.64.0/19
- Non-prod LON: 10.245.96.0/19

### Project Naming Convention
Format: `{env}-{bu}-{team}-{service}-{project_code}`
- env: p (production) or np (non-production)
- bu: business unit code
- team: team code
- service: service identifier
- project_code: unique project identifier

### Remote State Backend
Configured to use GCS bucket: `thinkbank-terraform-state-glz001` with prefix `landing-zone`