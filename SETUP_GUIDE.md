# GCP Landing Zone Setup Guide

## Prerequisites

Before running Terraform, ensure you have:

1. **Google Cloud Organization**: Access to thinkbank.co.za organization with Organization Admin role
2. **Billing Account**: Active billing account with proper permissions
3. **Local Environment**:
   - Terraform >= 1.0 installed
   - Google Cloud SDK (gcloud) installed and configured
   - Appropriate IAM permissions (Organization Admin, Billing Account Admin)

## Initial Manual Setup Steps

### 1. Enable Required APIs at Organization Level

```bash
# Authenticate with appropriate permissions
gcloud auth login
gcloud config set project [EXISTING_PROJECT_ID]

# Enable essential APIs
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable serviceusage.googleapis.com
```

### 2. Create Terraform State Bucket

```bash
# Create a GCS bucket for Terraform state (in an existing project)
gsutil mb -p [EXISTING_PROJECT_ID] -c STANDARD -l africa-south1 gs://thinkbank-terraform-state-glz001/
gsutil versioning set on gs://thinkbank-terraform-state-glz001/
gsutil lifecycle set lifecycle.json gs://thinkbank-terraform-state-glz001/
```

Create `lifecycle.json`:
```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 10,
          "isLive": false
        }
      }
    ]
  }
}
```

### 3. Configure Terraform Variables

Copy the example file and update with your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with:
- Organization domain: thinkbank.co.za
- Billing account ID
- Organization ID (get it with: `gcloud organizations list`)
- Admin group email
- Your private ASN for BGP

## Terraform Deployment

### Phase 1: Foundation

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply (this will create the folder structure and base projects)
terraform apply tfplan
```

## Post-Terraform Manual Steps

### 1. Dedicated Interconnect Configuration

Since your interconnects are already provisioned and waiting, you'll need to:

1. **Update terraform.tfvars with actual interconnect names**:
   ```hcl
   interconnect_attachments = {
     primary_attach_1 = {
       interconnect_name  = "your-actual-interconnect-name-1"  # Get from Console
       region            = "africa-south1"
       router_key        = "primary"
       bandwidth         = "BPS_10G"
       vlan_id          = 100  # Coordinate with network team
       candidate_subnets = ["169.254.100.0/29"]
     }
     primary_attach_2 = {
       interconnect_name  = "your-actual-interconnect-name-2"  # Get from Console
       region            = "africa-south1"
       router_key        = "primary"
       bandwidth         = "BPS_10G"
       vlan_id          = 101  # Coordinate with network team
       candidate_subnets = ["169.254.101.0/29"]
     }
   }
   ```

2. **Verify Interconnect Names**:
   ```bash
   # List existing interconnects
   gcloud compute interconnects list
   ```

3. **After Terraform Apply**:
   - VLAN attachments will be created automatically
   - BGP sessions will be established
   - Coordinate with network team to:
     - Configure BGP on on-premises routers
     - Use the BGP peering IPs from Cloud Console
     - Verify route advertisement both ways

4. **Verify Connectivity**:
   ```bash
   # Check BGP session status
   gcloud compute routers get-status cloud-router-primary \
     --region=africa-south1 \
     --project=p-iss-cet-transit-glz001
   ```

### 2. Identity Configuration

1. **Set up Google Cloud Directory Sync (GCDS)**:
   - Download GCDS from: https://support.google.com/a/answer/106368
   - Install on a Windows server with access to AD
   - Configure GCDS:
     - LDAP connection to on-premises AD
     - Map AD OUs to Cloud Identity groups
     - Configure sync schedule (recommended: every 4 hours)
   - Run initial sync in simulation mode
   - Verify results and run full sync

2. **Configure Azure AD Federation**:
   - In Cloud Identity Admin Console:
     - Go to Security → Set up single sign-on (SSO) with third party IdP
     - Download SAML metadata
   - In Azure AD:
     - Create new Enterprise Application
     - Configure SAML SSO with Cloud Identity metadata
     - Map user attributes
   - Test SSO with a test user

### 3. Security Configuration

1. **Enable Security Command Center Standard**:
   ```bash
   # Enable SCC (requires manual acceptance of terms in Console)
   gcloud scc settings update \
     --organization=[ORG_ID] \
     --enable-asset-discovery \
     --enable-finding-notifications
   ```

2. **Configure VPC Service Controls**:
   - The perimeter is created but needs projects added:
   ```bash
   # Add projects to VPC-SC perimeter as they're created
   gcloud access-context-manager perimeters update thinkbank_perimeter \
     --add-resources=projects/[PROJECT_NUMBER]
   ```

3. **Review Firewall Policies**:
   - Check hierarchical firewall rules in Console
   - Adjust priority and rules as needed
   - Test connectivity before enforcing strict rules

### 4. Logging Integration

1. **Configure Splunk Integration**:
   - In Splunk, install Google Cloud Platform Add-on
   - Create a Pub/Sub input with:
     - Project: p-iss-cet-logging-glz001
     - Subscription: splunk-log-subscription
   - Create service account key for Splunk (or use Workload Identity)
   - Configure index and source type mappings

2. **Verify Log Flow**:
   ```bash
   # Check if logs are being exported
   gcloud logging sinks describe org-splunk-export-sink \
     --organization=[ORG_ID]
   
   # Monitor Pub/Sub metrics
   gcloud monitoring dashboards create \
     --config-from-file=logging-dashboard.json
   ```

### 5. Network Connectivity Center Verification

```bash
# Verify NCC hub status
gcloud network-connectivity hubs describe global-ncc-hub \
  --project=p-iss-cet-transit-glz001

# Check spoke connections
gcloud network-connectivity spokes list \
  --project=p-iss-cet-transit-glz001
```

### 6. DNS Configuration

1. **Configure DNS Forwarding**:
   ```bash
   # Create inbound DNS policy for on-prem to GCP resolution
   gcloud dns policies create on-prem-inbound \
     --networks=shared-vpc-prod-za \
     --enable-inbound-forwarding \
     --project=p-iss-cet-vpc-za-glz001
   ```

2. **Update On-Premises DNS**:
   - Add conditional forwarders on BIND/Windows DNS
   - Point *.gcp.thinkbank.co.za to Cloud DNS inbound endpoints
   - Test resolution both ways

## Ongoing Operations

### Adding New Business Units

1. Create folder structure:
```hcl
# Add to Terraform configuration
resource "google_folder" "bu_retail" {
  display_name = "BU-Retail"
  parent       = google_folder.prod_environments.name
}
```

2. Create projects using the established naming convention:
   - Production: p-[bu]-[team]-[service]-[code]
   - Non-production: np-[bu]-[team]-[service]-[code]

### Monitoring and Maintenance

1. **Regular Reviews**:
   - Security Command Center findings (weekly)
   - Firewall rule effectiveness (monthly)
   - Cost optimization recommendations (monthly)
   - Access reviews (quarterly)

2. **Updates**:
   - Keep Terraform modules updated
   - Review and apply security patches
   - Update organization policies as needed

## Troubleshooting

### Common Issues

1. **Terraform State Lock**:
   ```bash
   # If state is locked, check who has it locked
   gsutil cat gs://thinkbank-terraform-state-glz001/landing-zone/default.tflock
   
   # Force unlock if necessary (use with caution)
   terraform force-unlock [LOCK_ID]
   ```

2. **API Enablement Issues**:
   - Ensure billing account is linked
   - Check organization policy constraints
   - Verify IAM permissions

3. **Network Connectivity**:
   - Verify BGP sessions are established
   - Check firewall rules (hierarchical and VPC-level)
   - Test with compute instances in different VPCs

## Support and Documentation

- Google Cloud Architecture Framework: https://cloud.google.com/architecture/framework
- Terraform Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Security Best Practices: https://cloud.google.com/security/best-practices

For internal support, contact the Cloud Engineering Team at cloud-team@thinkbank.co.za