# Root Module Outputs

output "organization_structure" {
  description = "Organization folder structure"
  value = {
    folders = module.organization.folder_ids
  }
}

output "shared_services_projects" {
  description = "Shared services project IDs"
  value       = module.shared_services.project_ids
}

output "network_configuration" {
  description = "Network configuration details"
  value = {
    ncc_hub_id = module.shared_services.ncc_hub_id
    vpcs       = module.shared_services.vpc_networks
    cloud_routers = module.shared_services.cloud_router_ids
  }
}

output "security_configuration" {
  description = "Security configuration details"
  value = {
    kms_keyrings         = module.shared_services.kms_keyrings
    vpc_sc_perimeter     = try(module.shared_services.vpc_sc_perimeter_name, null)
    firewall_policy_id   = try(module.shared_services.firewall_policy_id, null)
  }
}

output "logging_configuration" {
  description = "Logging and monitoring configuration"
  value       = module.shared_services.logging_configuration
}

output "terraform_service_account" {
  description = "Terraform automation service account"
  value = {
    email = google_service_account.terraform_sa.email
    id    = google_service_account.terraform_sa.id
  }
}

output "next_steps" {
  description = "Next steps for completing the landing zone setup"
  value = {
    manual_steps = [
      "1. Configure Dedicated Interconnects in the Google Cloud Console",
      "2. Set up VLAN attachments for the interconnects",
      "3. Configure BGP sessions on both GCP and on-premises routers",
      "4. Set up Google Cloud Directory Sync (GCDS)",
      "5. Configure Azure AD SAML federation with Cloud Identity",
      "6. Configure Splunk to consume logs from the Pub/Sub subscription",
      "7. Enable Security Command Center Standard Tier via Console",
      "8. Review and customize hierarchical firewall policies",
      "9. Add projects to VPC Service Controls perimeter as needed",
      "10. Create business unit folders and projects using the established patterns"
    ]
  }
}