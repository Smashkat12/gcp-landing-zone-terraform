# Shared Services Module Outputs

output "project_ids" {
  description = "Map of project IDs"
  value = {
    transit         = google_project.transit.project_id
    vpc_za_prod    = google_project.vpc_hosts["vpc_za_prod"].project_id
    vpc_za_nonprod = google_project.vpc_hosts["vpc_za_nonprod"].project_id
    vpc_lon_prod   = google_project.vpc_hosts["vpc_lon_prod"].project_id
    vpc_lon_nonprod = google_project.vpc_hosts["vpc_lon_nonprod"].project_id
    security       = google_project.security.project_id
    logging        = google_project.logging.project_id
    monitoring     = google_project.monitoring.project_id
  }
}

output "ncc_hub_id" {
  description = "Network Connectivity Center Hub ID"
  value       = google_network_connectivity_hub.ncc_hub.id
}

output "ncc_hub_name" {
  description = "Network Connectivity Center Hub name"
  value       = google_network_connectivity_hub.ncc_hub.name
}

output "cloud_router_ids" {
  description = "Map of Cloud Router IDs"
  value = {
    for k, v in google_compute_router.cloud_routers : k => v.id
  }
}

output "vpc_networks" {
  description = "Map of VPC network details"
  value = {
    for k, v in module.shared_vpcs : k => {
      vpc_id          = v.vpc_id
      vpc_name        = v.vpc_name
      vpc_self_link   = v.vpc_self_link
      subnet_ids      = v.subnet_ids
      subnet_self_links = v.subnet_self_links
    }
  }
}

output "kms_keyrings" {
  description = "KMS keyring information from security module"
  value       = module.security.kms_keyrings
}

output "logging_configuration" {
  description = "Logging configuration details"
  value       = module.logging.configuration
}