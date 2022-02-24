variable "project_id" {
  type        = string
  description = "Identifier of a project for hosting GKE clusters fleet."
}

variable "clusters" {
  type        = map(map(string))
  description = "The object with clusters definitions. Each entry is a cluster name with subnet, ip_range_base and region attributes."
}

variable "gke_connect_agent_users" {
  type        = list(string)
  description = "List of Google Accounts to configure GKE Connect Gateway Access for."
  default     = []
}

variable "bastion_enabled" {
  type        = bool
  description = "Flag that determines provisioning of bastion VM instance."
  default     = false
}

variable "bastion_subnet_ip_range" {
  type        = string
  description = "IP range for test subnet."
  default     = "172.16.1.0/24"
}

variable "bastion_subnet_region" {
  type        = string
  description = "GCP region for test subnet and VM."
  default     = "europe-west2"
}
