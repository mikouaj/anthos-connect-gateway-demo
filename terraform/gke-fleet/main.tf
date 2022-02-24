locals {
  clusters = [for cluster in var.gke_clusters : {
    project  = split("/", cluster)[1]
    location = split("/", cluster)[3]
    name     = split("/", cluster)[5]
  }]
}

/*
resource "google_gke_hub_feature" "acm" {
  provider   = google-beta
  project    = var.fleet_host_project_id
  name       = "configmanagement"
  location   = "global"
}
*/

resource "google_gke_hub_membership" "gke-hub-members" {
  provider = google-beta
  project  = var.fleet_host_project_id
  for_each = {
    for cluster in local.clusters : cluster.name => cluster
  }
  membership_id = each.value.name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/projects/${each.value.project}/locations/${each.value.location}/clusters/${each.key}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/projects/${each.value.project}/locations/${each.value.location}/clusters/${each.key}"
  }
}

resource "google_gke_hub_feature_membership" "feature_member" {
  provider = google-beta
  project  = var.fleet_host_project_id
  for_each = {
    for cluster in local.clusters : cluster.name => cluster
  }
  location   = "global"
  feature    = "configmanagement"
  membership = google_gke_hub_membership.gke-hub-members[each.key].membership_id
  configmanagement {
    version = "1.10.1"
    config_sync {
      source_format = "unstructured"
      git {
        sync_repo                 = google_sourcerepo_repository.acm.url
        secret_type               = "gcpserviceaccount"
        gcp_service_account_email = google_service_account.acm.email
        sync_branch               = "main"
      }
    }
  }
}