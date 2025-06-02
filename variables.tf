# Organization Configuration
variable "org_domain" {
  description = "The organization domain name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.org_domain))
    error_message = "Organization domain must be a valid domain name."
  }
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
  validation {
    condition     = can(regex("^[A-Z0-9]{6}-[A-Z0-9]{6}-[A-Z0-9]{6}$", var.billing_account))
    error_message = "Billing account must be in the format XXXXXX-XXXXXX-XXXXXX."
  }
}

variable "org_id" {
  description = "The organization ID (optional, will be looked up if not provided)"
  type        = string
  default     = ""
}

# Shared Services Configuration
variable "shared_services_bu" {
  description = "Business unit code for shared services"
  type        = string
  default     = "iss"
  validation {
    condition     = can(regex("^[a-z]{2,5}$", var.shared_services_bu))
    error_message = "Business unit code must be 2-5 lowercase letters."
  }
}

variable "shared_services_team" {
  description = "Team code for shared services"
  type        = string
  default     = "cet"
  validation {
    condition     = can(regex("^[a-z]{2,5}$", var.shared_services_team))
    error_message = "Team code must be 2-5 lowercase letters."
  }
}

variable "shared_services_project" {
  description = "Project code for shared services"
  type        = string
  default     = "glz001"
  validation {
    condition     = can(regex("^[a-z0-9]{3,8}$", var.shared_services_project))
    error_message = "Project code must be 3-8 lowercase alphanumeric characters."
  }
}

# Network Configuration
variable "gcp_cidr_range" {
  description = "CIDR range allocated for GCP use"
  type        = string
  default     = "10.245.0.0/17"
  validation {
    condition     = can(cidrhost(var.gcp_cidr_range, 0))
    error_message = "GCP CIDR range must be a valid CIDR notation."
  }
}

variable "onprem_cidr_ranges" {
  description = "List of on-premises CIDR ranges"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12"]
  validation {
    condition = alltrue([
      for cidr in var.onprem_cidr_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All on-premises CIDR ranges must be valid CIDR notation."
  }
}

variable "cloud_router_asn" {
  description = "ASN for Cloud Router BGP sessions"
  type        = string
  default     = "65001"
  validation {
    condition     = can(regex("^[0-9]+$", var.cloud_router_asn))
    error_message = "Cloud Router ASN must be a valid AS number."
  }
}

# Regions Configuration
variable "primary_region" {
  description = "Primary GCP region"
  type        = string
  default     = "africa-south1"
}

variable "dr_region" {
  description = "Disaster recovery GCP region"
  type        = string
  default     = "europe-west2"
}

# Admin Configuration
variable "admin_group_email" {
  description = "Email address of the admin group"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_group_email))
    error_message = "Admin group email must be a valid email address."
  }
}

variable "terraform_sa_name" {
  description = "Name for the Terraform service account"
  type        = string
  default     = "terraform-automation"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.terraform_sa_name))
    error_message = "Service account name must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

# Security Configuration
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

# Tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    environment = "shared"
    owner       = "platform-team"
    project     = "landing-zone"
    managed_by  = "terraform"
  }
}

# Interconnect Configuration
variable "interconnect_attachments" {
  description = "Configuration for existing interconnect VLAN attachments"
  type = map(object({
    interconnect_name  = string  # Name of the existing interconnect
    region            = string  # Region where attachment will be created
    router_key        = string  # Key to reference the cloud router (primary/dr)
    bandwidth         = string  # Bandwidth (e.g., BPS_10G)
    vlan_id          = number  # VLAN tag
    candidate_subnets = list(string) # BGP session IPs
  }))
  default = {
    primary_attach_1 = {
      interconnect_name  = "interconnect-jhb-1"
      region            = "africa-south1"
      router_key        = "primary"
      bandwidth         = "BPS_10G"
      vlan_id          = 100
      candidate_subnets = ["169.254.100.0/29"]
    }
    primary_attach_2 = {
      interconnect_name  = "interconnect-jhb-2"
      region            = "africa-south1"
      router_key        = "primary"
      bandwidth         = "BPS_10G"
      vlan_id          = 101
      candidate_subnets = ["169.254.101.0/29"]
    }
  }
}

# DNS Configuration
variable "private_dns_zone" {
  description = "Private DNS zone for GCP resources"
  type        = string
  default     = "gcp.thinkbank.co.za"
}

variable "public_dns_zone" {
  description = "Public DNS zone"
  type        = string
  default     = "thinkbank.co.za"
}

# Monitoring and Logging
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 365
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention days must be between 1 and 3653 (10 years)."
  }
}

variable "enable_export_to_splunk" {
  description = "Enable log export to Splunk"
  type        = bool
  default     = true
}

# Budget and Cost Management
variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 10000
  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [50, 80, 100]
  validation {
    condition = alltrue([
      for threshold in var.budget_alert_thresholds : threshold > 0 && threshold <= 100
    ])
    error_message = "Budget alert thresholds must be between 0 and 100."
  }
}
