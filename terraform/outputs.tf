output "clusters" {
  value = [for cluster in google_container_cluster.gke : cluster.id]
}

output "acm_repo_url" {
  value = module.gke-fleet.acm_repo_url
}
