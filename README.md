# Anthos Connect Gateway demo

The following repository contains code for infrastructure and tools that are setting up
[Fleet](https://cloud.google.com/anthos/multicluster-management/fleets) of
[GKE](https://cloud.google.com/kubernetes-engine) clusters with
[Anthos Connect Gateway](https://cloud.google.com/anthos/multicluster-management/gateway/using) in a
fully IaC driven way.

---

## Contents

* [terraform](./terraform) folder contains code required to provision the infrastructure
* [gke-connect-agent-generator](./gke-connect-agent-generator) folder contains tool for generating
[GKE Connect Agent](https://cloud.google.com/anthos/multicluster-management/connect/overview) manifests
for clusters in a fleet. The Agent is required for Connect Gateway operation.
* [gke-connect-gateway-generator](./gke-connect-gateway-generator) folder contains tool for generating
[Anthos Connect Gateway](https://cloud.google.com/anthos/multicluster-management/gateway/using)
`ClusterRole` and `ClusterRoleBinding` manifests required for Connect Gateway operation.

## Usage

1. Provision demo infrastructure with Terraform

   * enter [terraform](./terraform) directory
   * create `terraform.tfvars` file (check [terraform README](./terraform/README.md) for more details)
   * run `terrafrom apply`

2. Clone Anthos Config Management repository

   *NOTE: adjust repository name and project identifiers in the below example*

   ```sh
   gcloud source repos clone acm-fleet-my-project-id --project=my-project-id
   ```

3. Use `gke-connect-agent-generator` to generate manifest files for Connect Agent

   *NOTE: check [gke-connect-agent-generator](./gke-connect-agent-generator/README.md)
   README for more usage details*

   ```sh
   python gke-connect-agent-generator.py -p my-project-id -d acm-fleet-my-project-id/connect-agent
   ```

4. Use `gke-connect-gateway-generator` to generate manifest files for Connect Gateway 

   *NOTE: check [gke-connect-gateway-generator](./gke-connect-gateway-generator/README.md)
   README for more usage details*

   ```sh
   python gke-connect-gateway-generator.py -u userOne@mydomian.com -u userTwo@mydomain.com -d acm-fleet-my-project-id/connect-gateway
   ```

5. Commit files

   ```sh
   cd acm-fleet-my-project-id
   git add .
   git commit -m "connect-gateway-demo"
   git push -u origin main
   ```

6. Wait for GKE clusters to synchronize configuration

7. Get cluster credentials from GKE Hub and **enjoy!**

   ```sh
   gcloud container hub memberships get-credentials my-cluster-one-membership-name --project=my-fleet-host-project-id
   gcloud container hub memberships get-credentials my-cluster-two-membership-name --project=my-fleet-host-project-id
   ```

## Design
