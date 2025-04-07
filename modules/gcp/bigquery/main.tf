locals {
  
  bq_tables = flatten([
    for dataset_key, values in var.bq_datasets : [
      for table_key, values in lookup(values, "tables") : {
        dataset_id = dataset_key
        table_id   = table_key
        deletion_protection = try(values.deletion_protection, false)
        friendly_name = try(values.friendly_name, table_key)
        description = try(values.description, null)
        source_uris = values.source_uris
        }
      ]
    ])

  bq_datasets_access_policy = flatten([
    for dataset_key, values in var.bq_datasets : [
      for role_key, members in lookup(values, "access") : {
        dataset_id = dataset_key
        role       = role_key
        members    = members
      }
    ]
  ])

  labels = var.labels

  postgres_password = var.postgres_password

  stored_procedures = {}
  cloudsql_scheduled_postgres_transfers = {}
}


resource "google_project_service" "bigquerydatatransfer"{
  project = var.project
  service = "bigquerydatatransfer.googleapis.com"
}

resource "google_project_service" "bigquery"{
  project = var.project
  service = "bigquery.googleapis.com"
}

resource "google_bigquery_dataset" "bq_datasets" {
  for_each              = var.bq_datasets
  dataset_id            = each.key
  location              = "US"
  project               = var.project
  max_time_travel_hours = 168

  # default_table_expiration_ms = 3600000 # 1 hr
  friendly_name         = each.key
  description           = each.value.dataset_description
  labels                = local.labels
  delete_contents_on_destroy = each.value.force_destroy

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


resource "google_bigquery_data_transfer_config" "cloudsql_postgres_transfer" {
  for_each = {
    for dt_config in var.cloudsql_scheduled_postgres_transfers: dt_config.name => dt_config
  }

  display_name   = each.key
  project        = var.project
  location       = "US"
  data_source_id = "postgresql"
  schedule       = each.value.schedule
  destination_dataset_id = google_bigquery_dataset.bq_datasets[each.value.destination_dataset].dataset_id
  params = {
    "assets": jsonencode(each.value.source_table_names)
    "connector.authentication.username": each.value.username
    "connector.authentication.password": var.postgres_password
    "connector.database": each.value.database
    "connector.endpoint.host": each.value.host
    "connector.endpoint.port": 5432
    "connector.encryptionMode": each.value.encryption_mode
    "connector.networkAttachment": try(each.value.network_attachment, null)
    "connector.schema": each.value.schema
    
  }
  service_account_name = var.service_account_email
  depends_on = [google_bigquery_dataset.bq_datasets]
}

resource "google_bigquery_table" "bq_tables" {
  depends_on = [google_bigquery_dataset.bq_datasets]

  project             = var.project

  for_each            = {
    for table in local.bq_tables: table.table_id => table
  }

  table_id            = each.key
  dataset_id          = each.value.dataset_id
  deletion_protection = each.value.deletion_protection
  friendly_name      = each.value.friendly_name
  description        = try(each.value.description, null)

  external_data_configuration {
    autodetect = true # Parquet files used
    source_format = "PARQUET"
    source_uris = each.value.source_uris
  }

  labels = local.labels
}