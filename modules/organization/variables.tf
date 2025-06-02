# Organization Module Variables

variable "org_id" {
  description = "The organization ID"
  type        = string
}

variable "billing_account" {
  description = "The billing account ID"
  type        = string
}

variable "folders" {
  description = "Folder names configuration"
  type = object({
    shared_services = string
    prod_envs      = string
    nonprod_envs   = string
    sandbox_envs   = string
  })
}

variable "admin_group" {
  description = "Admin group email for organization-level permissions"
  type        = string
}