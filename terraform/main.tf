locals {
  clusters = flatten([
    for cluster_name, cluster in var.clusters : {
      name              = cluster_name
      subnet            = cluster.subnet
      region            = cluster.region
      ip_range_nodes    = cidrsubnet(cluster.ip_range_base, 10, 0)
      ip_range_master   = cidrsubnet(cluster.ip_range_base, 12, 16)
      ip_range_pods     = cidrsubnet(cluster.ip_range_base, 2, 1)
      ip_range_services = cidrsubnet(cluster.ip_range_base, 4, 8)
      pods_per_node     = 110
      sa_name           = "gke-${cluster_name}"
    }
  ])
  apis = [
    { "name" : "container.googleapis.com", "disable" : false },
    { "name" : "sourcerepo.googleapis.com", "disable" : false },
    { "name" : "anthos.googleapis.com", "disable" : true },
    { "name" : "gkehub.googleapis.com", "disable" : false },
    { "name" : "multiclustermetering.googleapis.com", "disable" : false },
    { "name" : "gkeconnect.googleapis.com", "disable" : false },
    { "name" : "connectgateway.googleapis.com", "disable" : false }
  ]
}

resource "google_project_service" "service" {
  for_each = {
    for api in local.apis : api.name => api.disable
  }
  project            = var.project_id
  service            = each.key
  disable_on_destroy = each.value
}

module "gke-fleet" {
  source                = "./gke-fleet"
  fleet_host_project_id = var.project_id
  gke_clusters = [for cluster in local.clusters : "projects/${var.project_id}/locations/${cluster.region}/clusters/${cluster.name}"]
  depends_on   = [google_container_cluster.gke]
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = module.gke-fleet.acm_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[config-management-system/root-reconciler]",
  ]
}