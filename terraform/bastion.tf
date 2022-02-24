resource "google_service_account" "bastion-server" {
  count        = var.bastion_enabled ? 1 : 0
  project      = var.project_id
  account_id   = "bastion-server"
  display_name = "Bastion server"
}

resource "google_project_iam_member" "bastion-gke-container-admin" {
  count   = var.bastion_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.bastion-server[1].email}"
}

resource "google_project_iam_member" "bastion-gkehub-admin" {
  count   = var.bastion_enabled ? 1 : 0
  project = var.project_id
  role    = "roles/gkehub.admin"
  member  = "serviceAccount:${google_service_account.bastion-server[1].email}"
}

data "google_compute_image" "centos8" {
  family  = "centos-stream-8"
  project = "centos-cloud"
}

data "google_compute_zones" "bastion-region-zones" {
  count   = var.bastion_enabled ? 1 : 0
  project = var.project_id
  region  = var.bastion_subnet_region
}

resource "google_compute_instance" "bastion-server" {
  count        = var.bastion_enabled ? 1 : 0
  project      = var.project_id
  name         = "bastion"
  machine_type = "g1-small"
  zone         = data.google_compute_zones.bastion-region-zones[1].names[0]
  boot_disk {
    initialize_params {
      image = data.google_compute_image.centos8.id
      size  = 20
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.bastion[1].id
    access_config {
    }
  }
  service_account {
    email  = google_service_account.bastion-server[1].email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_subnetwork" "bastion" {
  count                    = var.bastion_enabled ? 1 : 0
  project                  = var.project_id
  name                     = "bastion"
  ip_cidr_range            = var.bastion_subnet_ip_range
  region                   = var.bastion_subnet_region
  network                  = google_compute_network.gke.id
  private_ip_google_access = true
}

resource "google_compute_firewall" "bastion-ssh" {
  count         = var.bastion_enabled ? 1 : 0
  project       = var.project_id
  name          = "bastion-ssh"
  network       = google_compute_network.gke.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_service_accounts = [google_service_account.bastion-server[1].email]
}

resource "google_compute_router" "router-bastion-region" {
  count   = var.bastion_enabled ? 1 : 0
  project = var.project_id
  name    = "router-bastion-region"
  region  = var.bastion_subnet_region
  network = google_compute_network.gke.id
}

resource "google_compute_router_nat" "nat-bastion-region" {
  count                              = var.bastion_enabled ? 1 : 0
  project                            = var.project_id
  name                               = "nat-bastion-region"
  router                             = google_compute_router.router-bastion-region[1].name
  region                             = google_compute_router.router-bastion-region[1].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}