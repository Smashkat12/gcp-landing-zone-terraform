# Security Module Outputs

output "kms_keyrings" {
  description = "Map of KMS keyring information"
  value = {
    for k, v in google_kms_key_ring.keyrings : k => {
      id       = v.id
      name     = v.name
      location = v.location
    }
  }
}

output "kms_keys" {
  description = "Map of KMS crypto key information"
  value = var.enable_cmek ? {
    for k, v in google_kms_crypto_key.keys : k => {
      id       = v.id
      name     = v.name
      key_ring = v.key_ring
    }
  } : {}
}

output "vpc_sc_perimeter_name" {
  description = "VPC Service Controls perimeter name"
  value       = var.enable_vpc_service_controls ? google_access_context_manager_service_perimeter.main[0].name : null
}

output "access_policy_id" {
  description = "Access Context Manager policy ID"
  value       = var.enable_vpc_service_controls ? google_access_context_manager_access_policy.policy[0].name : null
}

output "firewall_policy_id" {
  description = "Hierarchical firewall policy ID"
  value       = google_compute_firewall_policy.org_policy.id
}

output "binary_authorization_policy" {
  description = "Binary Authorization policy name"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.policy[0].id : null
}