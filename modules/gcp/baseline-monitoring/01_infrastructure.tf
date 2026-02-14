# LOG-BASED METRICS (Iterated per project)
resource "google_logging_metric" "oom_events" {
  for_each = toset(var.monitored_project_ids)

  name    = "k8s_oom_events"
  project = each.value
  
  description = "Count of OOMKilled events from GKE containers"
  filter      = "resource.type=\"k8s_container\" AND textPayload:\"OOMKilled\""
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# INFRASTRUCTURE DASHBOARD
resource "google_monitoring_dashboard" "infrastructure_dashboard" {
  project      = var.infra_ops_project_id
  
  dashboard_json = <<EOF
{
  "displayName": "1. Infrastructure Overview",
  "dashboardFilters": [
    {
      "filterType": "RESOURCE_LABEL",
      "labelKey": "project_id",
      "templateVariable": "project_id",
      "stringValue": ""
    }
  ],
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Node CPU Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\"",
                "aggregation": { "perSeriesAligner": "ALIGN_MEAN", "crossSeriesReducer": "REDUCE_MEAN", "groupByFields": ["resource.label.node_name"] }
              }
            },
            "plotType": "LINE"
          }]
        }
      },
      {
        "title": "Node Memory Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/memory/allocatable_utilization\" resource.type=\"k8s_node\"",
                "aggregation": { "perSeriesAligner": "ALIGN_MEAN", "crossSeriesReducer": "REDUCE_MEAN", "groupByFields": ["resource.label.node_name"] }
              }
            },
            "plotType": "LINE"
          }]
        }
      },
      {
        "title": "Disk Utilization (%)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/ephemeral_storage/used_bytes\" resource.type=\"k8s_node\"",
                 "aggregation": { "perSeriesAligner": "ALIGN_MEAN", "crossSeriesReducer": "REDUCE_MEAN", "groupByFields": ["resource.label.node_name"] }
              }
            },
             "plotType": "LINE"
          }]
        }
      },
      {
        "title": "Disk Saturation (Throttled IOPS)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"compute.googleapis.com/instance/disk/throttled_read_ops_count\" resource.type=\"gce_instance\"",
                "aggregation": { "perSeriesAligner": "ALIGN_RATE", "crossSeriesReducer": "REDUCE_MEAN", "groupByFields": ["resource.label.instance_name"] }
              }
            },
            "plotType": "LINE"
          }]
        }
      },
      {
        "title": "Container Restart Rate (By Pod)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\"",
                "aggregation": { 
                  "perSeriesAligner": "ALIGN_RATE", 
                  "crossSeriesReducer": "REDUCE_SUM", 
                  "groupByFields": [
                    "resource.label.cluster_name",
                    "resource.label.namespace_name", 
                    "resource.label.pod_name",
                    "resource.label.container_name"
                  ] 
                }
              }
            },
            "plotType": "STACKED_BAR"
          }]
        }
      },
      {
        "title": "Specific OOM Events (By Pod)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"logging.googleapis.com/user/k8s_oom_events\" resource.type=\"k8s_container\"",
                "aggregation": { 
                  "perSeriesAligner": "ALIGN_RATE",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": [
                    "resource.label.cluster_name",
                    "resource.label.namespace_name", 
                    "resource.label.pod_name",
                    "resource.label.container_name"
                  ]
                }
              }
            },
            "plotType": "STACKED_BAR"
          }]
        }
      }
    ]
  }
}
EOF
}
