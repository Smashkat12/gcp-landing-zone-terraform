# Network Module Variables

variable "project_id" {
  description = "The project ID where the VPC will be created"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "region" {
  description = "The region for the VPC and subnets"
  type        = string
}

variable "cidr_range" {
  description = "Primary CIDR range for the VPC"
  type        = string
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    name        = string
    cidr        = string
    description = string
    secondary_ranges = optional(list(object({
      name = string
      cidr = string
    })), [])
  }))
}

variable "enable_private_google_access" {
  description = "Enable private Google access for subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "ncc_hub_name" {
  description = "Name of the Network Connectivity Center hub to connect as spoke"
  type        = string
  default     = null
}

variable "onprem_cidr_ranges" {
  description = "List of on-premises CIDR ranges for routing"
  type        = list(string)
}

variable "create_dns_zone" {
  description = "Whether to create a private DNS zone"
  type        = bool
  default     = true
}

variable "dns_domain" {
  description = "Domain name for private DNS zone"
  type        = string
  default     = "thinkbank.co.za"
}

variable "create_cloud_router" {
  description = "Whether to create a cloud router (for transit networks)"
  type        = bool
  default     = false
}

variable "cloud_router_asn" {
  description = "ASN for Cloud Router (if created)"
  type        = string
  default     = "65001"
}