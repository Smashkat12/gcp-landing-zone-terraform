# Security Module
# Manages KMS, VPC Service Controls, and Security Command Center

# KMS Keyrings and Keys
resource "google_kms_key_ring" "keyrings" {
  for_each = toset([var.primary_region, var.dr_region])
  
  name     = "keyring-${each.value}"
  project  = var.security_project_id
  location = each.value
}

# CMEK keys for different services
locals {
  cmek_keys = {
    compute = {
      name            = "compute-disk-encryption"
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "7776000s" # 90 days
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    }
    storage = {
      name            = "storage-bucket-encryption"
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "7776000s"
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    }
    bigquery = {
      name            = "bigquery-dataset-encryption"
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "7776000s"
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    }
    logging = {
      name            = "logging-bucket-encryption"
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "7776000s"
      algorithm       = "GOOGLE_SYMMETRIC_ENCRYPTION"
    }
  }
}

resource "google_kms_crypto_key" "keys" {
  for_each = var.enable_cmek ? {
    for item in flatten([
      for region in [var.primary_region, var.dr_region] : [
        for key_name, key_config in local.cmek_keys : {
          key = "${region}_${key_name}"
          region = region
          config = key_config
        }
      ]
    ]) : item.key => item
  } : {}
  
  name            = each.value.config.name
  key_ring        = google_kms_key_ring.keyrings[each.value.region].id
  purpose         = each.value.config.purpose
  rotation_period = each.value.config.rotation_period
  
  version_template {
    algorithm = each.value.config.algorithm
  }
  
  labels = {
    purpose = lower(replace(each.value.config.name, "-", "_"))
    region  = each.value.region
  }
}

# Grant crypto key encrypter/decrypter role to service accounts
resource "google_kms_crypto_key_iam_member" "service_account_access" {
  for_each = var.enable_cmek ? {
    for item in flatten([
      for key_id, key in google_kms_crypto_key.keys : [
        for sa in [
          "service-${data.google_project.security.number}@compute-system.iam.gserviceaccount.com",
          "service-${data.google_project.security.number}@gs-project-accounts.iam.gserviceaccount.com",
          "bq-${data.google_project.security.number}@bigquery-encryption.iam.gserviceaccount.com"
        ] : {
          key = "${key_id}_${sa}"
          crypto_key_id = key.id
          service_account = sa
        }
      ]
    ]) : item.key => item
  } : {}
  
  crypto_key_id = each.value.crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value.service_account}"
}

# Data source for security project
data "google_project" "security" {
  project_id = var.security_project_id
}

# VPC Service Controls - Access Policy
resource "google_access_context_manager_access_policy" "policy" {
  count = var.enable_vpc_service_controls ? 1 : 0
  
  parent = "organizations/${var.org_id}"
  title  = "ThinkBank Access Policy"
  scopes = ["organizations/${var.org_id}"]
}

# Access Levels
resource "google_access_context_manager_access_level" "corporate_access" {
  count = var.enable_vpc_service_controls ? 1 : 0
  
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/accessLevels/corporate_access"
  title  = "Corporate Network Access"
  
  basic {
    combining_function = "AND"
    
    conditions {
      # IP allowlist - to be updated with actual corporate IPs
      ip_subnetworks = concat(
        ["10.245.0.0/17"], # GCP ranges
        var.onprem_cidr_ranges
      )
      
      # Require specific group membership
      members = ["group:${var.admin_group}"]
    }
  }
}

# Service Perimeter
resource "google_access_context_manager_service_perimeter" "main" {
  count = var.enable_vpc_service_controls ? 1 : 0
  
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy[0].name}/servicePerimeters/thinkbank_perimeter"
  title  = "ThinkBank Security Perimeter"
  
  perimeter_type = "PERIMETER_TYPE_REGULAR"
  
  status {
    # Resources to be protected - will be populated with actual project numbers
    resources = [
      "projects/${data.google_project.security.number}"
    ]
    
    # Services to protect
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "cloudkms.googleapis.com",
      "logging.googleapis.com",
      "pubsub.googleapis.com",
      "spanner.googleapis.com",
      "sqladmin.googleapis.com",
      "bigtable.googleapis.com",
      "dataflow.googleapis.com",
      "dataproc.googleapis.com",
      "ml.googleapis.com",
      "dlp.googleapis.com",
      "cloudfunctions.googleapis.com",
      "secretmanager.googleapis.com",
      "artifactregistry.googleapis.com"
    ]
    
    access_levels = [
      google_access_context_manager_access_level.corporate_access[0].name
    ]
    
    # VPC accessible services
    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = ["RESTRICTED-SERVICES"]
    }
  }
  
  # Allow specific egress rules if needed
  spec {
    egress_policies {
      egress_from {
        identity_type = "ANY_USER_ACCOUNT"
      }
      egress_to {
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
}

# Security Command Center Setup
resource "google_scc_organization_scc_module" "scc_enablement" {
  count = var.enable_security_command_center ? 1 : 0
  
  organization = var.org_id
  
  # This is a placeholder - actual SCC enablement requires manual steps
  # or use of gcloud commands wrapped in null_resource
}

# Enable Security Command Center services
resource "null_resource" "enable_scc" {
  count = var.enable_security_command_center ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      gcloud scc settings update \
        --organization=${var.org_id} \
        --enable-asset-discovery \
        --enable-finding-notification
    EOT
  }
  
  triggers = {
    org_id = var.org_id
  }
}

# Organization Policy Constraints for Security
resource "google_organization_policy" "enforce_cmek" {
  count = var.enable_cmek ? 1 : 0
  
  org_id     = var.org_id
  constraint = "gcp.restrictNonCmekServices"
  
  list_policy {
    deny {
      all = false
      values = [] # Add services that should not use CMEK
    }
  }
}

# Hierarchical Firewall Policy
resource "google_compute_firewall_policy" "org_policy" {
  short_name  = "org-security-policy"
  description = "Organization-wide security firewall policy"
  parent      = "organizations/${var.org_id}"
}

# Firewall rules in the hierarchical policy
resource "google_compute_firewall_policy_rule" "deny_all_ingress" {
  firewall_policy = google_compute_firewall_policy.org_policy.id
  priority        = 2147483647 # Lowest priority
  action          = "deny"
  direction       = "INGRESS"
  
  match {
    src_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
  
  enable_logging = true
}

resource "google_compute_firewall_policy_rule" "allow_internal" {
  firewall_policy = google_compute_firewall_policy.org_policy.id
  priority        = 1000
  action          = "allow"
  direction       = "INGRESS"
  
  match {
    src_ip_ranges = concat(
      ["10.245.0.0/17"], # GCP internal
      var.onprem_cidr_ranges
    )
    layer4_configs {
      ip_protocol = "all"
    }
  }
  
  enable_logging = true
}

# Associate firewall policy with organization
resource "google_compute_firewall_policy_association" "org_association" {
  firewall_policy = google_compute_firewall_policy.org_policy.id
  attachment_target = "organizations/${var.org_id}"
  name              = "org-policy-association"
}

# Binary Authorization Policy (for container security)
resource "google_binary_authorization_policy" "policy" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project = var.security_project_id
  
  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.security_project_id}/*"
  }
  
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.prod_attestor[0].name
    ]
  }
}

# Binary Authorization Attestor
resource "google_binary_authorization_attestor" "prod_attestor" {
  count = var.enable_binary_authorization ? 1 : 0
  
  name    = "prod-attestor"
  project = var.security_project_id
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.attestor_note[0].name
    
    public_keys {
      id = data.google_kms_crypto_key_version.attestor_key[0].id
      pkix_public_key {
        public_key_pem      = data.google_kms_crypto_key_version.attestor_key[0].public_key[0].pem
        signature_algorithm = data.google_kms_crypto_key_version.attestor_key[0].public_key[0].algorithm
      }
    }
  }
}

# Container Analysis Note for Binary Authorization
resource "google_container_analysis_note" "attestor_note" {
  count = var.enable_binary_authorization ? 1 : 0
  
  name    = "prod-attestor-note"
  project = var.security_project_id
  
  attestation_authority {
    hint {
      human_readable_name = "Production Attestor"
    }
  }
}

# Data source for attestor key
data "google_kms_crypto_key_version" "attestor_key" {
  count = var.enable_binary_authorization ? 1 : 0
  
  crypto_key = google_kms_crypto_key.keys["${var.primary_region}_compute"].id
}