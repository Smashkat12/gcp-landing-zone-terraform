# Security Module Variables

variable "org_id" {
  description = "The organization ID"
  type        = string
}

variable "security_project_id" {
  description = "The project ID for security resources"
  type        = string
}

variable "primary_region" {
  description = "Primary region for resources"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
}

variable "admin_group" {
  description = "Admin group email for permissions"
  type        = string
}

variable "enable_cmek" {
  description = "Enable Customer-Managed Encryption Keys"
  type        = bool
  default     = true
}

variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = true
}

variable "enable_security_command_center" {
  description = "Enable Security Command Center"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for container security"
  type        = bool
  default     = false
}

variable "onprem_cidr_ranges" {
  description = "List of on-premises CIDR ranges for access policies"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12"]
}