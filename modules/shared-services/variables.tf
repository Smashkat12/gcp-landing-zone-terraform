# Shared Services Module Variables

variable "org_id" {
  description = "The organization ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "shared_services_folder_id" {
  description = "The folder ID for shared services"
  type        = string
}

variable "projects" {
  description = "Map of project names"
  type = object({
    transit            = string
    vpc_za_prod       = string
    vpc_za_nonprod    = string
    vpc_lon_prod      = string
    vpc_lon_nonprod   = string
    security          = string
    logging           = string
    monitoring        = string
  })
}

variable "primary_region" {
  description = "Primary GCP region"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery GCP region"
  type        = string
}

variable "network_cidrs" {
  description = "Network CIDR allocations"
  type = object({
    prod_za    = string
    prod_lon   = string
    nonprod_za = string
    nonprod_lon = string
  })
}

variable "subnets" {
  description = "Subnet CIDR allocations"
  type = object({
    prod_za_workloads    = string
    prod_za_gke_pods     = string
    prod_za_gke_services = string
    prod_za_management   = string
    prod_lon_workloads    = string
    prod_lon_gke_pods     = string
    prod_lon_gke_services = string
    prod_lon_management   = string
    nonprod_za_workloads    = string
    nonprod_za_gke_pods     = string
    nonprod_za_gke_services = string
    nonprod_za_management   = string
    nonprod_lon_workloads    = string
    nonprod_lon_gke_pods     = string
    nonprod_lon_gke_services = string
    nonprod_lon_management   = string
  })
}

variable "onprem_cidr_ranges" {
  description = "List of on-premises CIDR ranges"
  type        = list(string)
}

variable "cloud_router_asn" {
  description = "ASN for Cloud Router BGP sessions"
  type        = string
}

variable "admin_group" {
  description = "Admin group email"
  type        = string
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = true
}

variable "enable_cmek" {
  description = "Enable Customer-Managed Encryption Keys"
  type        = bool
  default     = true
}

variable "enable_security_command_center" {
  description = "Enable Security Command Center"
  type        = bool
  default     = true
}

variable "interconnect_attachments" {
  description = "Configuration for interconnect VLAN attachments"
  type = map(object({
    interconnect_name  = string
    region            = string
    router_key        = string
    bandwidth         = string
    vlan_id          = number
    candidate_subnets = list(string)
  }))
  default = {}