# Shared Services Module
# Creates all shared service projects and core infrastructure

# Enable required APIs at organization level
resource "google_project_service" "org_required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = var.projects.transit
  service = each.value
}

# Transit/Connectivity Project
resource "google_project" "transit" {
  name            = "Transit Connectivity"
  project_id      = var.projects.transit
  folder_id       = var.shared_services_folder_id
  billing_account = var.billing_account
  
  labels = {
    environment = "shared"
    purpose     = "network-transit"
  }
}

# Enable APIs for transit project
resource "google_project_service" "transit_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "networkconnectivity.googleapis.com",
    "dns.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = google_project.transit.project_id
  service = each.value
}

# VPC Host Projects
resource "google_project" "vpc_hosts" {
  for_each = {
    vpc_za_prod    = var.projects.vpc_za_prod
    vpc_za_nonprod = var.projects.vpc_za_nonprod
    vpc_lon_prod   = var.projects.vpc_lon_prod
    vpc_lon_nonprod = var.projects.vpc_lon_nonprod
  }
  
  name            = "Shared VPC Host - ${each.key}"
  project_id      = each.value
  folder_id       = var.shared_services_folder_id
  billing_account = var.billing_account
  
  labels = {
    environment = contains(split("_", each.key), "prod") ? "production" : "non-production"
    region      = contains(split("_", each.key), "za") ? "africa-south1" : "europe-west2"
    purpose     = "shared-vpc-host"
  }
}

# Enable Shared VPC for host projects
resource "google_compute_shared_vpc_host_project" "hosts" {
  for_each = google_project.vpc_hosts
  
  project = each.value.project_id
  
  depends_on = [google_project_service.vpc_host_apis]
}

# Enable APIs for VPC host projects
resource "google_project_service" "vpc_host_apis" {
  for_each = {
    for item in flatten([
      for project_key, project in google_project.vpc_hosts : [
        for api in [
          "compute.googleapis.com",
          "dns.googleapis.com",
          "logging.googleapis.com",
          "monitoring.googleapis.com",
          "servicenetworking.googleapis.com"
        ] : {
          key     = "${project_key}_${api}"
          project = project.project_id
          api     = api
        }
      ]
    ]) : item.key => item
  }
  
  project = each.value.project
  service = each.value.api
}

# Security Project
resource "google_project" "security" {
  name            = "Security Tools"
  project_id      = var.projects.security
  folder_id       = var.shared_services_folder_id
  billing_account = var.billing_account
  
  labels = {
    environment = "shared"
    purpose     = "security"
  }
}

# Enable APIs for security project
resource "google_project_service" "security_apis" {
  for_each = toset([
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "cloudasset.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  
  project = google_project.security.project_id
  service = each.value
}

# Logging Project
resource "google_project" "logging" {
  name            = "Centralized Logging"
  project_id      = var.projects.logging
  folder_id       = var.shared_services_folder_id
  billing_account = var.billing_account
  
  labels = {
    environment = "shared"
    purpose     = "logging"
  }
}

# Enable APIs for logging project
resource "google_project_service" "logging_apis" {
  for_each = toset([
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com"
  ])
  
  project = google_project.logging.project_id
  service = each.value
}

# Monitoring Project
resource "google_project" "monitoring" {
  name            = "Centralized Monitoring"
  project_id      = var.projects.monitoring
  folder_id       = var.shared_services_folder_id
  billing_account = var.billing_account
  
  labels = {
    environment = "shared"
    purpose     = "monitoring"
  }
}

# Enable APIs for monitoring project
resource "google_project_service" "monitoring_apis" {
  for_each = toset([
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com"
  ])
  
  project = google_project.monitoring.project_id
  service = each.value
}

# Network Connectivity Center Hub
resource "google_network_connectivity_hub" "ncc_hub" {
  name        = "global-ncc-hub"
  description = "Global Network Connectivity Center Hub for hybrid connectivity"
  project     = google_project.transit.project_id
  
  labels = {
    environment = "shared"
    purpose     = "network-hub"
  }
  
  depends_on = [google_project_service.transit_apis]
}

# Create VPCs in each host project
module "shared_vpcs" {
  source = "../network"
  
  for_each = {
    vpc_za_prod = {
      project_id = google_project.vpc_hosts["vpc_za_prod"].project_id
      region     = var.primary_region
      vpc_name   = "shared-vpc-prod-za"
      cidr_range = var.network_cidrs.prod_za
      subnets    = {
        workloads = {
          name        = "subnet-prod-za-workloads"
          cidr        = var.subnets.prod_za_workloads
          description = "Production workloads subnet - africa-south1"
        }
        gke_pods = {
          name        = "subnet-prod-za-gke-pods"
          cidr        = var.subnets.prod_za_gke_pods
          description = "Production GKE pods subnet - africa-south1"
        }
        gke_services = {
          name        = "subnet-prod-za-gke-services"
          cidr        = var.subnets.prod_za_gke_services
          description = "Production GKE services subnet - africa-south1"
        }
        management = {
          name        = "subnet-prod-za-management"
          cidr        = var.subnets.prod_za_management
          description = "Production management subnet - africa-south1"
        }
      }
    }
    vpc_za_nonprod = {
      project_id = google_project.vpc_hosts["vpc_za_nonprod"].project_id
      region     = var.primary_region
      vpc_name   = "shared-vpc-nonprod-za"
      cidr_range = var.network_cidrs.nonprod_za
      subnets    = {
        workloads = {
          name        = "subnet-nonprod-za-workloads"
          cidr        = var.subnets.nonprod_za_workloads
          description = "Non-production workloads subnet - africa-south1"
        }
        gke_pods = {
          name        = "subnet-nonprod-za-gke-pods"
          cidr        = var.subnets.nonprod_za_gke_pods
          description = "Non-production GKE pods subnet - africa-south1"
        }
        gke_services = {
          name        = "subnet-nonprod-za-gke-services"
          cidr        = var.subnets.nonprod_za_gke_services
          description = "Non-production GKE services subnet - africa-south1"
        }
        management = {
          name        = "subnet-nonprod-za-management"
          cidr        = var.subnets.nonprod_za_management
          description = "Non-production management subnet - africa-south1"
        }
      }
    }
    vpc_lon_prod = {
      project_id = google_project.vpc_hosts["vpc_lon_prod"].project_id
      region     = var.dr_region
      vpc_name   = "shared-vpc-prod-lon"
      cidr_range = var.network_cidrs.prod_lon
      subnets    = {
        workloads = {
          name        = "subnet-prod-lon-workloads"
          cidr        = var.subnets.prod_lon_workloads
          description = "Production workloads subnet - europe-west2"
        }
        gke_pods = {
          name        = "subnet-prod-lon-gke-pods"
          cidr        = var.subnets.prod_lon_gke_pods
          description = "Production GKE pods subnet - europe-west2"
        }
        gke_services = {
          name        = "subnet-prod-lon-gke-services"
          cidr        = var.subnets.prod_lon_gke_services
          description = "Production GKE services subnet - europe-west2"
        }
        management = {
          name        = "subnet-prod-lon-management"
          cidr        = var.subnets.prod_lon_management
          description = "Production management subnet - europe-west2"
        }
      }
    }
    vpc_lon_nonprod = {
      project_id = google_project.vpc_hosts["vpc_lon_nonprod"].project_id
      region     = var.dr_region
      vpc_name   = "shared-vpc-nonprod-lon"
      cidr_range = var.network_cidrs.nonprod_lon
      subnets    = {
        workloads = {
          name        = "subnet-nonprod-lon-workloads"
          cidr        = var.subnets.nonprod_lon_workloads
          description = "Non-production workloads subnet - europe-west2"
        }
        gke_pods = {
          name        = "subnet-nonprod-lon-gke-pods"
          cidr        = var.subnets.nonprod_lon_gke_pods
          description = "Non-production GKE pods subnet - europe-west2"
        }
        gke_services = {
          name        = "subnet-nonprod-lon-gke-services"
          cidr        = var.subnets.nonprod_lon_gke_services
          description = "Non-production GKE services subnet - europe-west2"
        }
        management = {
          name        = "subnet-nonprod-lon-management"
          cidr        = var.subnets.nonprod_lon_management
          description = "Non-production management subnet - europe-west2"
        }
      }
    }
  }
  
  enable_private_google_access = true
  enable_flow_logs            = true
  ncc_hub_name               = google_network_connectivity_hub.ncc_hub.name
  onprem_cidr_ranges         = var.onprem_cidr_ranges
  
  depends_on = [
    google_compute_shared_vpc_host_project.hosts,
    google_project_service.vpc_host_apis
  ]
}

# Create a transit VPC in the transit project for interconnect attachments
resource "google_compute_network" "transit_vpc" {
  name                    = "transit-vpc"
  project                 = google_project.transit.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  
  depends_on = [google_project_service.transit_apis]
}

# Cloud Routers for Interconnect attachments (in transit project)
resource "google_compute_router" "cloud_routers" {
  for_each = {
    primary = {
      name   = "cloud-router-primary"
      region = var.primary_region
    }
    dr = {
      name   = "cloud-router-dr"
      region = var.dr_region
    }
  }
  
  name    = each.value.name
  network = google_compute_network.transit_vpc.id
  region  = each.value.region
  project = google_project.transit.project_id
  
  bgp {
    asn               = var.cloud_router_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    
    # Advertise all GCP ranges to on-premises
    advertised_ip_ranges {
      range       = "10.245.0.0/17"
      description = "GCP aggregate range"
    }
  }
}

# VLAN attachments for existing interconnects
resource "google_compute_interconnect_attachment" "attachments" {
  for_each = var.interconnect_attachments
  
  name                     = each.key
  project                  = google_project.transit.project_id
  region                   = each.value.region
  router                   = google_compute_router.cloud_routers[each.value.router_key].id
  interconnect             = each.value.interconnect_name
  bandwidth                = each.value.bandwidth
  vlan_tag8021q           = each.value.vlan_id
  candidate_subnets       = each.value.candidate_subnets
  type                    = "DEDICATED"
  admin_enabled           = true
  
  description = "VLAN attachment for ${each.value.interconnect_name}"
}

# Security Module - KMS Setup
module "security" {
  source = "../security"
  
  org_id              = var.org_id
  security_project_id = google_project.security.project_id
  primary_region      = var.primary_region
  dr_region          = var.dr_region
  admin_group        = var.admin_group
  
  enable_cmek                    = var.enable_cmek
  enable_vpc_service_controls    = var.enable_vpc_service_controls
  enable_security_command_center = var.enable_security_command_center
  
  depends_on = [google_project_service.security_apis]
}

# Logging Setup
module "logging" {
  source = "../logging"
  
  org_id              = var.org_id
  logging_project_id  = google_project.logging.project_id
  monitoring_project_id = google_project.monitoring.project_id
  
  log_retention_days = 365
  enable_splunk_export = true
  
  depends_on = [
    google_project_service.logging_apis,
    google_project_service.monitoring_apis
  ]
}