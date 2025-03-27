locals {
  bq_datasets_access_policy = flatten([
    for dataset_key, values in var.bq_datasets : [
      for role_key, members in lookup(values, "access") : {
        dataset_id = dataset_key
        role       = role_key
        members    = members
      }
    ]
  ])

  labels = {
    env = "epicore-stage"
  }

  bq_tables = flatten([
    for dataset_key, values in var.bq_datasets : [
      for table_key, values in lookup(values, "tables") : {
        dataset_id = dataset_key
        table_id   = table_key
        # schema     = values.schema
        # deletion_protection = values.deletion_protection
        # friendly_name = values.friendly_name
        # connection_name = values.source_connection_name
        }
      ]
    ])

  postgres_password = var.postgres_password

  stored_procedures = {}
  scheduled_queries = {}
}


resource "google_project_service" "bigquerydatatransfer"{
  project = var.gcp.project
  service = "bigquerydatatransfer.googleapis.com"
}

resource "google_project_service" "bigquery"{
  project = var.gcp.project
  service = "bigquery.googleapis.com"
}
resource "google_bigquery_dataset" "bq_datasets" {
  # depends_on            = [google_bigquery_connection.connection]
  for_each              = var.bq_datasets
  dataset_id            = each.key
  location              = each.value.location
  project               = var.gcp.project
  max_time_travel_hours = 168

  default_table_expiration_ms = 3600000
  friendly_name         = each.key
  description           = each.value.dataset_description
  labels                = each.value.labels
  delete_contents_on_destroy = each.value.force_destroy

  # access {
  #   role   = "OWNER"
  #   user_by_email = "big-query-sa@epicore-stage.iam.gserviceaccount.com"
  # }

  # access {
  #   role   = "READER"
  #   domain  = "epicorebiosystems.com"
  # }
}

resource "google_bigquery_dataset_iam_binding" "bq_access" {
  depends_on = [google_bigquery_dataset.bq_datasets]
  for_each = {
    for datasets_access in local.bq_datasets_access_policy : "${datasets_access.dataset_id}.${datasets_access.role}" => datasets_access
  }
  dataset_id = each.value.dataset_id
  role       = "roles/${each.value.role}"
  members    = each.value.members
}


# resource "google_bigquery_connection" "cloudsql_connection" {

#   for_each      = {
#     for cloudsql_connection in var.cloudsql_connections: cloudsql_connection.name => cloudsql_connection
#   }

#   connection_id = each.key
#   location      = each.value.location
#   friendly_name = each.key
#   cloud_sql {
#       instance_id = each.value.instance_id
#       database    = each.value.database
#       type        = "POSTGRES"
#       credential {
#         username = "postgres"
#         password = postgres_password
#       }
#   }
# }

# resource "google_bigquery_connection" "datalake_connection" {

#   for_each      = {
#     for cloudsql_connection in var.external_connections:
#       cloudsql_connection.name => cloudsql_connection
#       # if lookup(cloudsql_connection, "connectionType", "") == "gcs" : 
#   }
#   project = var.gcp.project
#   connection_id = each.key
#   location      = try(each.value.location, "US")
#   friendly_name = try(each.value.friendly_name, each.key)
#   cloud_resource {}
# # }

# resource "google_bigquery_table" "bq_tables" {
#   depends_on = [google_bigquery_dataset.bq_datasets]

#   project             = var.gcp.project

#   for_each = local.bq_tables

#   table_id            = each.key

#   dataset_id          = each.value.dataset_id
  
#   deletion_protection = each.value.deletion_protection

#   friendly_name      = each.value.friendly_name
#   schema = each.value.schema


#   external_data_configuration {
#     autodetect = true

#     connection_id = google_bigquery_connection.connection[each.value.connection_name].id
#   }

#   labels = local.labels
# }

# resource "google_bigquery_routine" "stored_procedures" {

#   for_each = var.stored_procedures
#   project      = var.gcp.project
#   dataset_id   = google_bigquery_dataset.bq_datasets.dataset_id
#   routine_id   = each.key
#   routine_type = "PROCEDURE"
#   language     = "SQL"
#   definition_body = templatefile("$template_file_path",{
#     project_id = var.gcp.project
#     dataset_id = google_bigquery_dataset.bq_datasets.dataset_id
#     }
#   )
# }

resource "google_bigquery_data_transfer_config" "postgres_transfer" {


  for_each      = {
    for dt_config in var.scheduled_queries: dt_config.name => dt_config
  }

  display_name   = each.key
  project        = var.gcp.project
  location       = each.value.location
  data_source_id = "postgresql"
  schedule       = each.value.schedule
  destination_dataset_id = google_bigquery_dataset.bq_datasets[each.value.destination_dataset].dataset_id
  params = {
    "assets": jsonencode(each.value.source_table_names)
    "connector.authentication.username": "postgres"
    "connector.authentication.password": var.postgres_password
    "connector.database": each.value.database
    "connector.endpoint.host": each.value.source_connection_name
    "connector.endpoint.port": 5432
    
  }
  service_account_name = google_service_account.service-accounts["big-query-sa"].email
  depends_on = [google_bigquery_dataset.bq_datasets]
}