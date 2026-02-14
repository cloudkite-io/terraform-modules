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
        "title": "Total Container Restarts",
        "scorecard": {
          "timeSeriesQuery": {
            "timeSeriesFilter": {
              "filter": "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\"",
              "aggregation": {
                "perSeriesAligner": "ALIGN_DELTA",
                "crossSeriesReducer": "REDUCE_SUM",
                "alignmentPeriod": "3600s"
              }
            },
            "unitOverride": "Restarts"
          },
          "sparkChartType": "SPARK_LINE"
        }
      },
      {
        "title": "Total OOM Crashes",
        "scorecard": {
          "timeSeriesQuery": {
            "timeSeriesFilter": {
              "filter": "metric.type=\"logging.googleapis.com/user/k8s_oom_events\" resource.type=\"k8s_container\"",
              "aggregation": {
                "perSeriesAligner": "ALIGN_DELTA",
                "crossSeriesReducer": "REDUCE_SUM",
                "alignmentPeriod": "3600s"
              }
            },
            "unitOverride": "Crashes"
          },
          "sparkChartType": "SPARK_BAR"
        }
      },
      {
        "title": "Top Nodes by CPU Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_MEAN",
                  "crossSeriesReducer": "REDUCE_MEAN",
                  "groupByFields": ["resource.label.node_name"]
                }
              }
            },
            "plotType": "LINE"
          }],
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "Top Nodes by Memory Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/memory/allocatable_utilization\" resource.type=\"k8s_node\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_MEAN",
                  "crossSeriesReducer": "REDUCE_MEAN",
                  "groupByFields": ["resource.label.node_name"]
                }
              }
            },
            "plotType": "LINE"
          }]
        }
      },
      {
        "title": "Top Fullest Disks (>80%)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/node/ephemeral_storage/used_bytes\" resource.type=\"k8s_node\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_MEAN",
                  "crossSeriesReducer": "REDUCE_MEAN",
                  "groupByFields": ["resource.label.node_name"]
                }
              }
            },
            "plotType": "STACKED_BAR"
          }]
        }
      },
      {
        "title": "Container Restarts (Count by Pod)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_DELTA", 
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": ["resource.label.pod_name", "resource.label.namespace_name"]
                }
              }
            },
            "plotType": "STACKED_BAR"
          }],
          "yAxis": {
            "label": "Count",
            "scale": "LINEAR"
          }
        }
      }
    ]
  }
}
EOF
}
