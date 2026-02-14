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
      "templateVariable": "project_id"
    },
    {
      "filterType": "RESOURCE_LABEL",
      "labelKey": "cluster_name",
      "templateVariable": "cluster_name"
    }
  ],
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Unhealthy Nodes",
        "scorecard": {
          "timeSeriesQuery": {
            "timeSeriesFilter": {
              "filter": "metric.type=\"kubernetes.io/node/status_condition\" resource.type=\"k8s_node\" metric.label.condition=\"Ready\" value.condition_state=\"false\"",
              "aggregation": {
                "perSeriesAligner": "ALIGN_NEXT_OLDER",
                "crossSeriesReducer": "REDUCE_COUNT",
                "alignmentPeriod": "60s"
              }
            },
            "unitOverride": "Nodes"
          }
        }
      },
      {
        "title": "Total Healthy Nodes",
        "scorecard": {
          "timeSeriesQuery": {
            "timeSeriesFilter": {
              "filter": "metric.type=\"kubernetes.io/node/status_condition\" resource.type=\"k8s_node\" metric.label.condition=\"Ready\" value.condition_state=\"true\"",
              "aggregation": {
                "perSeriesAligner": "ALIGN_NEXT_OLDER",
                "crossSeriesReducer": "REDUCE_COUNT",
                "alignmentPeriod": "60s"
              }
            },
            "unitOverride": "Nodes"
          }
        }
      },
      {
        "title": "Top Restarting Containers (By Pod Name)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_DELTA",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": ["resource.label.namespace_name", "resource.label.pod_name"]
                }
              }
            },
            "plotType": "STACKED_BAR"
          }],
          "yAxis": {
             "label": "Restarts",
             "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "Top OOM Crashes (By Pod Name)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"logging.googleapis.com/user/k8s_oom_events\" resource.type=\"k8s_container\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_DELTA",
                  "crossSeriesReducer": "REDUCE_SUM",
                  "groupByFields": ["resource.label.namespace_name", "resource.label.pod_name"]
                }
              }
            },
            "plotType": "STACKED_BAR"
          }],
           "yAxis": {
             "label": "OOM Count",
             "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "Disk Capacity & Usage (Table)",
        "collapsibleGroup": {
          "collapsed": false
        },
        "text": {
          "content": "This table shows the current Used vs Total capacity per node.",
          "format": "MARKDOWN"
        }
      },
      {
        "title": "Disk Usage Table",
        "table": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"kubernetes.io/node/ephemeral_storage/used_bytes\" resource.type=\"k8s_node\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_NEXT_OLDER",
                    "crossSeriesReducer": "REDUCE_LAST",
                    "groupByFields": ["resource.label.node_name"]
                  }
                }
              },
              "tableTemplate": "Used Bytes"
            },
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"kubernetes.io/node/ephemeral_storage/allocatable_bytes\" resource.type=\"k8s_node\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_NEXT_OLDER",
                    "crossSeriesReducer": "REDUCE_LAST",
                    "groupByFields": ["resource.label.node_name"]
                  }
                }
              },
              "tableTemplate": "Total Capacity"
            }
          ]
        }
      },
      {
        "title": "Disk IOPS (Read vs Write)",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"compute.googleapis.com/instance/disk/read_ops_count\" resource.type=\"gce_instance\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM"
                  }
                },
                "unitOverride": "Read Ops"
              },
              "plotType": "LINE",
              "legendTemplate": "Read IOPS"
            },
            {
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"compute.googleapis.com/instance/disk/write_ops_count\" resource.type=\"gce_instance\"",
                  "aggregation": {
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM"
                  }
                },
                "unitOverride": "Write Ops"
              },
              "plotType": "LINE",
              "legendTemplate": "Write IOPS"
            }
          ],
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      }
    ]
  }
}
EOF
}
