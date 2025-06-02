# Organization Module Outputs

output "folder_ids" {
  description = "Map of folder names to their IDs"
  value = {
    shared_services = google_folder.shared_services.id
    prod_envs      = google_folder.prod_environments.id
    nonprod_envs   = google_folder.nonprod_environments.id
    sandbox_envs   = google_folder.sandbox_environments.id
  }
}

output "folder_names" {
  description = "Map of folder names to their full resource names"
  value = {
    shared_services = google_folder.shared_services.name
    prod_envs      = google_folder.prod_environments.name
    nonprod_envs   = google_folder.nonprod_environments.name
    sandbox_envs   = google_folder.sandbox_environments.name
  }
}