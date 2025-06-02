# Network Module
# Creates VPC networks, subnets, and NCC spoke connections

# Create VPC Network
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = true
  
  description = "Shared VPC network for ${var.vpc_name}"
}

# Create Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets
  
  name                     = each.value.name
  project                  = var.project_id
  network                  = google_compute_network.vpc.id
  region                   = var.region
  ip_cidr_range           = each.value.cidr
  description             = each.value.description
  private_ip_google_access = var.enable_private_google_access
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
  
  secondary_ip_range = lookup(each.value, "secondary_ranges", []) != [] ? [
    for range in each.value.secondary_ranges : {
      range_name    = range.name
      ip_cidr_range = range.cidr
    }
  ] : []
}

# Routes to on-premises via interconnect
# Note: Routes to on-prem will be automatically created via BGP when interconnect is attached
# Static routes are created here as placeholders and for documentation

resource "google_compute_route" "to_onprem" {
  for_each = toset(var.onprem_cidr_ranges)
  
  name             = "${var.vpc_name}-to-onprem-${replace(each.value, "/[./]/", "-")}"
  project          = var.project_id
  network          = google_compute_network.vpc.id
  dest_range       = each.value
  next_hop_instance = "" # Will be populated by BGP routes from interconnect
  priority         = 900
  
  lifecycle {
    ignore_changes = [next_hop_instance, next_hop_ip, next_hop_vpn_tunnel]
  }
}

# Route all traffic (including internet-bound) to on-premises
resource "google_compute_route" "default_to_onprem" {
  name             = "${var.vpc_name}-default-to-onprem"
  project          = var.project_id
  network          = google_compute_network.vpc.id
  dest_range       = "0.0.0.0/0"
  priority         = 1000
  next_hop_instance = "" # Will be populated by BGP routes from interconnect
  
  tags = ["route-through-onprem"]
  
  lifecycle {
    ignore_changes = [next_hop_instance, next_hop_ip, next_hop_vpn_tunnel]
  }
}

# Create Network Connectivity Center Spoke
resource "google_network_connectivity_spoke" "vpc_spoke" {
  count = var.ncc_hub_name != null ? 1 : 0
  
  name     = "${var.vpc_name}-spoke"
  project  = var.project_id
  location = var.region
  hub      = var.ncc_hub_name
  
  description = "NCC spoke for ${var.vpc_name}"
  
  linked_vpc_network {
    uri                               = google_compute_network.vpc.self_link
    exclude_export_ranges             = []
    include_export_ranges             = ["ALL_IPV4_RANGES"]
  }
  
  labels = {
    vpc_name = var.vpc_name
    region   = var.region
  }
}

# Firewall Rules - Hierarchical policies will be defined at org/folder level
# VPC-level firewall rules for specific requirements

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  direction = "INGRESS"
  priority  = 1000
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = concat(
    [var.cidr_range],
    var.onprem_cidr_ranges
  )
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.vpc_name}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  direction = "INGRESS"
  priority  = 900
  
  allow {
    protocol = "tcp"
  }
  
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  
  target_tags = ["allow-health-checks"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Deny all egress by default
resource "google_compute_firewall" "deny_all_egress" {
  name    = "${var.vpc_name}-deny-all-egress"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  direction = "EGRESS"
  priority  = 65534
  
  deny {
    protocol = "all"
  }
  
  destination_ranges = ["0.0.0.0/0"]
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow egress to Google APIs via Private Google Access
resource "google_compute_firewall" "allow_google_apis" {
  name    = "${var.vpc_name}-allow-google-apis"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  direction = "EGRESS"
  priority  = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  
  destination_ranges = ["199.36.153.8/30"] # restricted.googleapis.com
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow egress to on-premises networks
resource "google_compute_firewall" "allow_egress_to_onprem" {
  name    = "${var.vpc_name}-allow-egress-to-onprem"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  direction = "EGRESS"
  priority  = 900
  
  allow {
    protocol = "all"
  }
  
  destination_ranges = var.onprem_cidr_ranges
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Cloud DNS - Private Zone for internal resolution
resource "google_dns_managed_zone" "private_zone" {
  count = var.create_dns_zone ? 1 : 0
  
  name        = "${var.vpc_name}-private"
  project     = var.project_id
  dns_name    = "${var.region}.gcp.${var.dns_domain}."
  description = "Private DNS zone for ${var.vpc_name}"
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

# Cloud Router for future interconnect attachments (if in transit project)
resource "google_compute_router" "router" {
  count = var.create_cloud_router ? 1 : 0
  
  name    = "${var.vpc_name}-router"
  project = var.project_id
  network = google_compute_network.vpc.id
  region  = var.region
  
  bgp {
    asn               = var.cloud_router_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
  }
}