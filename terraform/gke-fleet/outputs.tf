output "acm_repo_id" {
  value = google_sourcerepo_repository.acm.id
}

output "acm_repo_url" {
  value = google_sourcerepo_repository.acm.url
}

output "acm_sa" {
  value = google_service_account.acm
}