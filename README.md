# GCP Landing Zone - ThinkBank

This repository contains the Terraform configuration for deploying a secure, compliant, and scalable Google Cloud Platform landing zone for ThinkBank.

## Architecture Overview

The landing zone implements:
- **Hub-and-spoke network topology** with Network Connectivity Center
- **Multi-region deployment** (africa-south1 primary, europe-west2 DR)
- **Hierarchical resource organization** with environment separation
- **Enterprise security controls** (VPC-SC, CMEK, SCC)
- **Hybrid connectivity** via Dedicated Interconnects
- **Centralized logging** with Splunk integration

## Directory Structure

```
.
├── main.tf                 # Root module configuration
├── variables.tf            # Root module variables
├── outputs.tf             # Root module outputs
├── terraform.tfvars.example # Example variables file
├── modules/               # Reusable Terraform modules
│   ├── organization/      # Organization and folder structure
│   ├── shared-services/   # Shared services projects and infrastructure
│   ├── network/          # VPC networks and connectivity
│   ├── security/         # Security controls (KMS, VPC-SC, etc.)
│   └── logging/          # Centralized logging and monitoring
├── SETUP_GUIDE.md        # Detailed setup instructions
├── README.md            # This file
└── CLAUDE.md           # AI assistant context
```

## Modules

### Organization Module
Creates the folder hierarchy and organization-level policies:
- Shared Services (00-Shared-Services)
- Production Environments (10-Prod-Environments)
- Non-Production Environments (20-Non-Prod-Environments)
- Sandbox Environments (30-Sandbox-Environments)

### Shared Services Module
Deploys core infrastructure projects:
- Transit connectivity project with NCC hub
- Shared VPC host projects (prod/nonprod for each region)
- Security tools project
- Centralized logging and monitoring projects

### Network Module
Manages VPC networks with:
- Subnet creation with Private Google Access
- Hierarchical and VPC-level firewall rules
- Cloud DNS private zones
- NCC spoke connections

### Security Module
Implements security controls:
- Cloud KMS keyrings and CMEK keys
- VPC Service Controls perimeter
- Security Command Center configuration
- Hierarchical firewall policies
- Binary Authorization (optional)

### Logging Module
Sets up centralized logging:
- Log sinks for audit, platform, and application logs
- Cloud Storage buckets with lifecycle policies
- Pub/Sub export to Splunk
- BigQuery dataset for log analytics
- Cloud Monitoring alerts

## Naming Conventions

Projects follow the pattern: `{env}-{bu}-{team}-{service}-{project_code}`
- `env`: p (production) or np (non-production)
- `bu`: Business unit code (e.g., iss for shared services)
- `team`: Team code (e.g., cet)
- `service`: Service identifier (e.g., transit, vpc-za)
- `project_code`: Unique identifier (e.g., glz001)

Example: `p-iss-cet-transit-glz001`

## Network Design

IP allocation (10.245.0.0/17):
- Production africa-south1: 10.245.0.0/19
- Production europe-west2: 10.245.32.0/19
- Non-production africa-south1: 10.245.64.0/19
- Non-production europe-west2: 10.245.96.0/19

Each VPC includes subnets for:
- Workloads
- GKE pods
- GKE services
- Management

## Quick Start

1. **Prerequisites**:
   - Terraform >= 1.0
   - Google Cloud SDK
   - Organization Admin permissions
   - Active billing account

2. **Configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deployment**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Post-deployment**: Follow the [SETUP_GUIDE.md](SETUP_GUIDE.md) for manual steps

## Security Considerations

- **No direct internet access**: All traffic (ingress/egress) routes through on-premises security stack
- All data encrypted at rest with CMEK
- VPC Service Controls protect against data exfiltration
- Hierarchical firewall policies enforce network security
- Comprehensive audit logging to Splunk
- Private Google Access via restricted.googleapis.com for GCP API access

## Cost Optimization

- Committed use discounts for predictable workloads
- Lifecycle policies for log storage
- Budget alerts and cost visibility through BigQuery
- Resource labeling for cost allocation

## Maintenance

- Regular security reviews via Security Command Center
- Terraform state stored in versioned GCS bucket
- Modular design allows incremental updates
- Policy-as-code for consistent governance

## Support

For issues or questions:
- Review [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions
- Check Terraform logs for deployment errors
- Contact cloud-team@thinkbank.co.za for internal support

## License

This is proprietary configuration for ThinkBank internal use only.