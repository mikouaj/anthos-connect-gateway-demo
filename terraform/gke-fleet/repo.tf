resource "google_service_account" "acm" {
  project      = var.fleet_host_project_id
  account_id   = "acm-repo-reader"
  display_name = "ACM repository reader"
}

resource "google_sourcerepo_repository" "acm" {
  project    = var.fleet_host_project_id
  name       = "acm-fleet-${var.fleet_host_project_id}"
}

resource "google_sourcerepo_repository_iam_member" "acm-reader" {
  project    = var.fleet_host_project_id
  repository = google_sourcerepo_repository.acm.name
  role       = "roles/source.reader"
  member     = "serviceAccount:${google_service_account.acm.email}"
}