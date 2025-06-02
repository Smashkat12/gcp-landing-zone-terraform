# Logging Module Outputs

output "log_bucket_names" {
  description = "Names of the log storage buckets"
  value = {
    for k, v in google_storage_bucket.log_buckets : k => v.name
  }
}

output "splunk_topic_id" {
  description = "Pub/Sub topic ID for Splunk export"
  value       = var.enable_splunk_export ? google_pubsub_topic.splunk_export[0].id : null
}

output "splunk_subscription_name" {
  description = "Pub/Sub subscription name for Splunk"
  value       = var.enable_splunk_export ? google_pubsub_subscription.splunk_subscription[0].name : null
}

output "log_sink_names" {
  description = "Names of the organization log sinks"
  value = {
    audit_logs    = google_logging_organization_sink.audit_logs.name
    platform_logs = google_logging_organization_sink.platform_logs.name
    splunk_export = var.enable_splunk_export ? google_logging_organization_sink.splunk_export[0].name : null
    bigquery      = google_logging_organization_sink.bigquery_analytics.name
  }
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for log analytics"
  value       = google_bigquery_dataset.log_analytics.dataset_id
}

output "notification_channel_ids" {
  description = "Monitoring notification channel IDs"
  value = {
    email = google_monitoring_notification_channel.email.id
  }
}

output "configuration" {
  description = "Logging configuration summary"
  value = {
    retention_days    = var.log_retention_days
    splunk_enabled    = var.enable_splunk_export
    log_analytics_bq  = google_bigquery_dataset.log_analytics.dataset_id
  }
}