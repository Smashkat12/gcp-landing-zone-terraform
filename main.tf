terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Configure remote state backend
  backend "gcs" {
    bucket = "thinkbank-terraform-state-glz001"
    prefix = "landing-zone"
  }
}

# Configure the Google Cloud Provider
provider "google" {
  default_labels = var.default_tags
}

provider "google-beta" {
  default_labels = var.default_tags
}

# Data sources for organization info
data "google_organization" "org" {
  domain = var.org_domain
}

data "google_billing_account" "billing" {
  billing_account = var.billing_account
}

# Local values for computed names and configurations
locals {
  # Folder naming
  folders = {
    shared_services = "00-shared-services"
    prod_envs      = "10-prod-environments"
    nonprod_envs   = "20-nonprod-environments"
    sandbox_envs   = "30-sandbox-environments"
  }

  # Project naming convention: {env}-{bu}-{team}-{service}-{project_code}
  shared_projects = {
    transit            = "p-${var.shared_services_bu}-${var.shared_services_team}-transit-${var.shared_services_project}"
    vpc_za_prod       = "p-${var.shared_services_bu}-${var.shared_services_team}-vpc-za-${var.shared_services_project}"
    vpc_za_nonprod    = "np-${var.shared_services_bu}-${var.shared_services_team}-vpc-za-${var.shared_services_project}"
    vpc_lon_prod      = "p-${var.shared_services_bu}-${var.shared_services_team}-vpc-lon-${var.shared_services_project}"
    vpc_lon_nonprod   = "np-${var.shared_services_bu}-${var.shared_services_team}-vpc-lon-${var.shared_services_project}"
    security          = "p-${var.shared_services_bu}-${var.shared_services_team}-security-${var.shared_services_project}"
    logging           = "p-${var.shared_services_bu}-${var.shared_services_team}-logging-${var.shared_services_project}"
    monitoring        = "p-${var.shared_services_bu}-${var.shared_services_team}-monitoring-${var.shared_services_project}"
  }

  # Network CIDR allocation
  network_cidrs = {
    prod_za        = "10.245.0.0/19"    # Production africa-south1
    prod_lon       = "10.245.32.0/19"   # Production europe-west2
    nonprod_za     = "10.245.64.0/19"   # Non-production africa-south1
    nonprod_lon    = "10.245.96.0/19"   # Non-production europe-west2
  }

  # Subnet allocation within each VPC
  subnets = {
    # Production africa-south1 (10.245.0.0/19)
    prod_za_workloads    = "10.245.0.0/22"    # 1,024 IPs for workloads
    prod_za_gke_pods     = "10.245.4.0/22"    # 1,024 IPs for GKE pods
    prod_za_gke_services = "10.245.8.0/24"    # 256 IPs for GKE services
    prod_za_management   = "10.245.9.0/24"    # 256 IPs for management
    
    # Production europe-west2 (10.245.32.0/19)
    prod_lon_workloads    = "10.245.32.0/22"  # 1,024 IPs for workloads
    prod_lon_gke_pods     = "10.245.36.0/22"  # 1,024 IPs for GKE pods
    prod_lon_gke_services = "10.245.40.0/24"  # 256 IPs for GKE services
    prod_lon_management   = "10.245.41.0/24"  # 256 IPs for management
    
    # Non-production africa-south1 (10.245.64.0/19)
    nonprod_za_workloads    = "10.245.64.0/22"  # 1,024 IPs for workloads
    nonprod_za_gke_pods     = "10.245.68.0/22"  # 1,024 IPs for GKE pods
    nonprod_za_gke_services = "10.245.72.0/24"  # 256 IPs for GKE services
    nonprod_za_management   = "10.245.73.0/24"  # 256 IPs for management
    
    # Non-production europe-west2 (10.245.96.0/19)
    nonprod_lon_workloads    = "10.245.96.0/22"   # 1,024 IPs for workloads
    nonprod_lon_gke_pods     = "10.245.100.0/22"  # 1,024 IPs for GKE pods
    nonprod_lon_gke_services = "10.245.104.0/24"  # 256 IPs for GKE services
    nonprod_lon_management   = "10.245.105.0/24"  # 256 IPs for management
  }
}

# Create organization structure
module "organization" {
  source = "./modules/organization"

  org_id          = data.google_organization.org.org_id
  billing_account = data.google_billing_account.billing.billing_account
  folders         = local.folders
  admin_group     = var.admin_group_email

  depends_on = [
    data.google_organization.org,
    data.google_billing_account.billing
  ]
}

# Create shared services projects and infrastructure
module "shared_services" {
  source = "./modules/shared-services"

  org_id                    = data.google_organization.org.org_id
  billing_account          = data.google_billing_account.billing.billing_account
  shared_services_folder_id = module.organization.folder_ids.shared_services
  projects                 = local.shared_projects
  
  # Network configuration
  primary_region     = var.primary_region
  dr_region         = var.dr_region
  network_cidrs     = local.network_cidrs
  subnets           = local.subnets
  onprem_cidr_ranges = var.onprem_cidr_ranges
  cloud_router_asn   = var.cloud_router_asn

  # Security configuration
  enable_vpc_service_controls      = var.enable_vpc_service_controls
  enable_cmek                     = var.enable_cmek
  enable_security_command_center  = var.enable_security_command_center
  
  # Interconnect configuration
  interconnect_attachments = var.interconnect_attachments
  
  admin_group = var.admin_group_email
  
  depends_on = [module.organization]
}

# Create Terraform service account for future automation
resource "google_service_account" "terraform_sa" {
  project     = module.shared_services.project_ids.security
  account_id  = var.terraform_sa_name
  display_name = "Terraform Automation Service Account"
  description = "Service account for Terraform-based infrastructure automation"
}

# Grant necessary permissions to Terraform service account
resource "google_organization_iam_member" "terraform_org_admin" {
  org_id = data.google_organization.org.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_organization_iam_member" "terraform_billing_admin" {
  org_id = data.google_organization.org.org_id
  role   = "roles/billing.admin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Additional roles for network and security management
resource "google_organization_iam_member" "terraform_network_admin" {
  org_id = data.google_organization.org.org_id
  role   = "roles/compute.networkAdmin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}

resource "google_organization_iam_member" "terraform_security_admin" {
  org_id = data.google_organization.org.org_id
  role   = "roles/securitycenter.admin"
  member = "serviceAccount:${google_service_account.terraform_sa.email}"
}
