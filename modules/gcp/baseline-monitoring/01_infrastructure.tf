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
  "displayName": "1. Infrastructure Overview (PromQL)",
  "dashboardFilters": [
    {
      "filterType": "RESOURCE_LABEL",
      "labelKey": "project_id",
      "templateVariable": "",
      "valueType": "STRING"
    }
  ],
  "gridLayout": {
    "columns": "2",
    "widgets": [
      {
        "title": "Healthy Nodes (Kubelet Status)",
        "scorecard": {
          "timeSeriesQuery": {
            "prometheusQuery": "count(up{job=\"kubelet\"} == 1)",
            "unitOverride": "Nodes"
          }
        }
      },
      {
        "title": "Unhealthy/Down Nodes",
        "scorecard": {
          "timeSeriesQuery": {
            "prometheusQuery": "count(up{job=\"kubelet\"} == 0) or vector(0)",
            "unitOverride": "Nodes"
          }
        }
      },
      {
        "title": "Cumulative Pod Restarts (Lifetime)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "prometheusQuery": "topk(20, sum by (pod, namespace) (container_restart_count) > 0)"
            },
            "plotType": "STACKED_BAR"
          }],
          "yAxis": {
             "label": "Total Restarts",
             "scale": "LINEAR"
          },
          "chartOptions": {
            "mode": "COLOR"
          }
        }
      },
      {
        "title": "Top OOM Crashes (Log-Based)",
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
        "title": "Disk Usage (Used vs Limit)",
        "timeSeriesTable": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "prometheusQuery": "sum(container_fs_usage_bytes{device=~\".+\"}) by (instance)"
              },
              "tableTemplate": "Used"
            },
            {
              "timeSeriesQuery": {
                "prometheusQuery": "sum(container_fs_limit_bytes{device=~\".+\"}) by (instance)"
              },
              "tableTemplate": "Total"
            }
          ],
          "metricVisualization": "NUMBER"
        }
      },
      {
        "title": "Disk IOPS (Reads vs Writes)",
        "xyChart": {
          "dataSets": [
            {
              "timeSeriesQuery": {
                "prometheusQuery": "sum(rate(container_fs_reads_total[5m])) by (instance)"
              },
              "plotType": "LINE",
              "legendTemplate": "Read IOPS"
            },
            {
              "timeSeriesQuery": {
                "prometheusQuery": "sum(rate(container_fs_writes_total[5m])) by (instance)"
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
