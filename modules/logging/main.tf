# Logging Module
# Centralized logging configuration with Splunk export

# Create logging buckets for long-term storage
resource "google_storage_bucket" "log_buckets" {
  for_each = toset(["audit-logs", "platform-logs", "application-logs"])
  
  name          = "${var.logging_project_id}-${each.value}"
  project       = var.logging_project_id
  location      = "AFRICA-SOUTH1"
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  retention_policy {
    retention_period = var.log_retention_days * 86400 # Convert days to seconds
    is_locked       = false
  }
  
  labels = {
    purpose = each.value
    env     = "shared"
  }
}

# Pub/Sub topic for Splunk export
resource "google_pubsub_topic" "splunk_export" {
  count = var.enable_splunk_export ? 1 : 0
  
  name    = "splunk-log-export"
  project = var.logging_project_id
  
  message_retention_duration = "86400s" # 1 day
  
  labels = {
    purpose = "splunk-export"
  }
}

# Pub/Sub subscription for Splunk
resource "google_pubsub_subscription" "splunk_subscription" {
  count = var.enable_splunk_export ? 1 : 0
  
  name    = "splunk-log-subscription"
  topic   = google_pubsub_topic.splunk_export[0].name
  project = var.logging_project_id
  
  ack_deadline_seconds       = 60
  message_retention_duration = "604800s" # 7 days
  
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  
  expiration_policy {
    ttl = "" # Never expire
  }
  
  labels = {
    purpose = "splunk-export"
  }
}

# Organization-level log sinks
resource "google_logging_organization_sink" "audit_logs" {
  name             = "org-audit-logs-sink"
  org_id           = var.org_id
  destination      = "storage.googleapis.com/${google_storage_bucket.log_buckets["audit-logs"].name}"
  include_children = true
  
  # Audit logs filter
  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity") OR
    log_id("cloudaudit.googleapis.com/data_access") OR
    log_id("cloudaudit.googleapis.com/system_event")
  EOT
}

# Platform logs sink
resource "google_logging_organization_sink" "platform_logs" {
  name             = "org-platform-logs-sink"
  org_id           = var.org_id
  destination      = "storage.googleapis.com/${google_storage_bucket.log_buckets["platform-logs"].name}"
  include_children = true
  
  # Platform logs filter
  filter = <<-EOT
    resource.type="gce_instance" OR
    resource.type="gke_cluster" OR
    resource.type="cloud_function" OR
    resource.type="cloud_run_revision" OR
    resource.type="k8s_container" OR
    resource.type="k8s_pod" OR
    resource.type="k8s_node"
  EOT
}

# Splunk export sink (if enabled)
resource "google_logging_organization_sink" "splunk_export" {
  count = var.enable_splunk_export ? 1 : 0
  
  name             = "org-splunk-export-sink"
  org_id           = var.org_id
  destination      = "pubsub.googleapis.com/${google_pubsub_topic.splunk_export[0].id}"
  include_children = true
  
  # Export all critical logs to Splunk
  filter = <<-EOT
    severity >= "WARNING" OR
    log_id("cloudaudit.googleapis.com/activity") OR
    log_id("cloudaudit.googleapis.com/data_access") OR
    (resource.type="gce_instance" AND severity >= "ERROR") OR
    (resource.type="gke_cluster" AND severity >= "ERROR")
  EOT
}

# Grant permissions to log sinks
resource "google_storage_bucket_iam_member" "audit_logs_writer" {
  bucket = google_storage_bucket.log_buckets["audit-logs"].name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.audit_logs.writer_identity
}

resource "google_storage_bucket_iam_member" "platform_logs_writer" {
  bucket = google_storage_bucket.log_buckets["platform-logs"].name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.platform_logs.writer_identity
}

resource "google_pubsub_topic_iam_member" "splunk_publisher" {
  count = var.enable_splunk_export ? 1 : 0
  
  project = var.logging_project_id
  topic   = google_pubsub_topic.splunk_export[0].name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.splunk_export[0].writer_identity
}

# Cloud Monitoring Workspace
resource "google_monitoring_monitored_project" "primary" {
  metrics_scope = "locations/global/metricsScopes/${var.monitoring_project_id}"
  name          = "locations/global/metricsScopes/${var.monitoring_project_id}/projects/${var.monitoring_project_id}"
}

# Notification channels for alerts
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  project      = var.monitoring_project_id
  
  labels = {
    email_address = var.alert_email
  }
  
  enabled = true
}

# Example uptime check for critical services
resource "google_monitoring_uptime_check_config" "https_check" {
  display_name = "HTTPS Uptime Check"
  project      = var.monitoring_project_id
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.monitoring_project_id
      host       = "api.thinkbank.co.za" # Example
    }
  }
}

# Alert policies
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate Alert"
  project      = var.monitoring_project_id
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Error rate exceeds threshold"
    
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"logging.googleapis.com/user/error_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 100
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.id]
  
  alert_strategy {
    auto_close = "86400s" # 24 hours
  }
}

# BigQuery dataset for log analytics
resource "google_bigquery_dataset" "log_analytics" {
  dataset_id                 = "log_analytics"
  project                    = var.logging_project_id
  friendly_name              = "Log Analytics Dataset"
  description                = "Dataset for log analysis and querying"
  location                   = "africa-south1"
  default_table_expiration_ms = var.log_retention_days * 24 * 60 * 60 * 1000
  
  labels = {
    purpose = "log-analytics"
  }
}

# Log router for BigQuery (for analytics)
resource "google_logging_organization_sink" "bigquery_analytics" {
  name             = "org-bigquery-analytics-sink"
  org_id           = var.org_id
  destination      = "bigquery.googleapis.com/projects/${var.logging_project_id}/datasets/${google_bigquery_dataset.log_analytics.dataset_id}"
  include_children = true
  
  # Sample of logs for analytics
  filter = <<-EOT
    sample(insertId, 0.1) AND
    (severity >= "WARNING" OR
     resource.type="gce_instance" OR
     resource.type="gke_cluster")
  EOT
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant BigQuery Data Editor role to the log sink
resource "google_bigquery_dataset_iam_member" "log_writer" {
  project    = var.logging_project_id
  dataset_id = google_bigquery_dataset.log_analytics.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_organization_sink.bigquery_analytics.writer_identity
}