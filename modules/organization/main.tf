# Organization and Folder Structure Module
# Creates the hierarchical folder structure for the GCP Landing Zone

locals {
  folder_display_names = {
    shared_services = "Shared Services"
    prod_envs      = "Production Environments"
    nonprod_envs   = "Non-Production Environments"
    sandbox_envs   = "Sandbox Environments"
  }
}

# Create top-level folders
resource "google_folder" "shared_services" {
  display_name = local.folder_display_names.shared_services
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "prod_environments" {
  display_name = local.folder_display_names.prod_envs
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "nonprod_environments" {
  display_name = local.folder_display_names.nonprod_envs
  parent       = "organizations/${var.org_id}"
}

resource "google_folder" "sandbox_environments" {
  display_name = local.folder_display_names.sandbox_envs
  parent       = "organizations/${var.org_id}"
}

# Organization policies - Example security baseline policies
resource "google_organization_policy" "disable_automatic_iam_grants" {
  org_id     = var.org_id
  constraint = "storage.uniformBucketLevelAccess"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "enforce_public_access_prevention" {
  org_id     = var.org_id
  constraint = "storage.publicAccessPrevention"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "require_os_login" {
  org_id     = var.org_id
  constraint = "compute.requireOsLogin"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "allowed_locations" {
  org_id     = var.org_id
  constraint = "gcp.resourceLocations"

  list_policy {
    allow {
      values = [
        "in:africa-south1-locations",
        "in:europe-west2-locations"
      ]
    }
  }
}

# Billing account association
resource "google_billing_account_iam_member" "org_billing_admin" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = "group:${var.admin_group}"
}

# Organization-level IAM for admin group
resource "google_organization_iam_member" "org_admin" {
  for_each = toset([
    "roles/resourcemanager.organizationAdmin",
    "roles/iam.organizationRoleAdmin",
    "roles/orgpolicy.policyAdmin"
  ])
  
  org_id = var.org_id
  role   = each.value
  member = "group:${var.admin_group}"
}