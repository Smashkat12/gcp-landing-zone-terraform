# Network Module Outputs

output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.id
  }
}

output "subnet_self_links" {
  description = "Map of subnet names to their self links"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.self_link
  }
}

output "subnet_cidrs" {
  description = "Map of subnet names to their CIDR ranges"
  value = {
    for k, v in google_compute_subnetwork.subnets : k => v.ip_cidr_range
  }
}

output "ncc_spoke_id" {
  description = "The ID of the NCC spoke (if created)"
  value       = var.ncc_hub_name != null ? google_network_connectivity_spoke.vpc_spoke[0].id : null
}

output "dns_zone_name" {
  description = "The name of the private DNS zone (if created)"
  value       = var.create_dns_zone ? google_dns_managed_zone.private_zone[0].name : null
}

output "cloud_router_id" {
  description = "The ID of the Cloud Router (if created)"
  value       = var.create_cloud_router ? google_compute_router.router[0].id : null
}