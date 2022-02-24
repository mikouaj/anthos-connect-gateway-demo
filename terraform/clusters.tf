resource "google_compute_subnetwork" "gke" {
  for_each = {
    for cluster in local.clusters : cluster.name => cluster
  }
  project                  = var.project_id
  name                     = each.value.subnet
  ip_cidr_range            = each.value.ip_range_nodes
  region                   = each.value.region
  network                  = google_compute_network.gke.id
  private_ip_google_access = true
}

resource "google_service_account" "gke-worker" {
  for_each     = toset([for cluster in local.clusters : cluster.name])
  project      = var.project_id
  account_id   = "gke-${each.key}"
  display_name = "GKE worker for ${each.key}"
}

resource "google_project_iam_member" "gke-worker-metrics" {
  for_each = toset([for cluster in local.clusters : cluster.name])
  project  = var.project_id
  role     = "roles/monitoring.metricWriter"
  member   = "serviceAccount:${google_service_account.gke-worker[each.key].email}"
}

resource "google_project_iam_member" "gke-worker-logs" {
  for_each = toset([for cluster in local.clusters : cluster.name])
  project  = var.project_id
  role     = "roles/logging.logWriter"
  member   = "serviceAccount:${google_service_account.gke-worker[each.key].email}"
}

resource "google_container_cluster" "gke" {
  for_each = {
    for cluster in local.clusters : cluster.name => cluster
  }
  project            = var.project_id
  name               = each.key
  location           = each.value.region
  initial_node_count = 1
  node_config {
    machine_type    = "n1-standard-2"
    service_account = google_service_account.gke-worker[each.key].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = each.value.ip_range_master
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.bastion_subnet_ip_range
      display_name = "Test Subnet IP Range"
    }
  }

  network                   = google_compute_network.gke.id
  subnetwork                = google_compute_subnetwork.gke[each.key].id
  networking_mode           = "VPC_NATIVE"
  default_max_pods_per_node = 110
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = each.value.ip_range_pods
    services_ipv4_cidr_block = each.value.ip_range_services
  }
  release_channel {
    channel = "REGULAR"
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
  }
  network_policy {
    enabled = true
  }
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}
