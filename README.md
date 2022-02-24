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

2. Set you GKE fleet project identifier in gcloud and as env variable

   ```sh
   gcloud config set project my-project-id
   export FLEET_PROJECT_ID=my-project-id
   ```

3. Clone Anthos Config Management repository

   ```sh
   gcloud source repos clone gke-config-management
   ```

4. Use `gke-connect-agent-generator` script to generate manifest files for Connect Agent

   ```sh
   python gke-connect-agent-generator/gke-connect-agent-generator.py -p $FLEET_PROJECT_ID -d gke-config-management
   ```

5. Use `gke-connect-gateway-generator` script to generate manifest files for Connect Gateway authentication

   *NOTE:* adjust Google Account identifiers of your users in a below example

   ```sh
   python gke-connect-gateway-generator/gke-connect-gateway-generator.py -u john@mydomian.com -u jane@mydomain.com -d gke-config-management
   ```

6. Commit generated files to the config management repository

   ```sh
   cd gke-config-management
   git add .
   git commit -m "connect-gateway-demo"
   git push -u origin main
   ```

7. Wait for GKE clusters to synchronize configuration

8. Get cluster credentials from GKE Hub and **enjoy!**

   ```sh
   gcloud container hub memberships get-credentials cluster-one
   gcloud container hub memberships get-credentials cluster-two
   ```

## Design

The infrastructure consists of N private GKE clusters that are registered fleet members.
The fleet uses Config Sync with a GIT repository provided by Source Code Repositories.

Optionally, a bastion host with a public IP address can be provisioned in the same VPC network for
troubleshooting purposes.

![connect-gateway-demo](./connect-gateway-demo.jpg)
