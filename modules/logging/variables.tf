# Logging Module Variables

variable "org_id" {
  description = "The organization ID"
  type        = string
}

variable "logging_project_id" {
  description = "The project ID for logging resources"
  type        = string
}

variable "monitoring_project_id" {
  description = "The project ID for monitoring resources"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 365
}

variable "enable_splunk_export" {
  description = "Enable log export to Splunk via Pub/Sub"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "ops-alerts@thinkbank.co.za"
}