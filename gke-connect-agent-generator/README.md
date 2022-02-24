# gke-connect-agent-generator

GKE Connect Agent Generator is a script that generates K8S manifests for running
[GKE Connect Agent](https://cloud.google.com/anthos/multicluster-management/connect/overview)
on each GKE cluster in a given GKE fleet.

The output manifests are meant for use with [Anthos Config Management](https://cloud.google.com/anthos/config-management)
unstructured repositories.

## Purpose

The script was created to fill the gap when GKE clusters are registered in a GKE fleet using Terraform
`google_gke_hub_membership` resource. Registering cluster in a fleet with Terraform (or via API) is
not causing agent installation on a cluster.

**NOTE:** using `gcloud container hub memberships
register` command generates manifests and deploys Connect Agent on a cluster automatically.

## Inputs

The scripts takes the following input arguments:

* `-p` `--project` *(Required)* the GKE fleet host project identifier.
* `-d` `--directory` *(Required)* the output directory where generated manifest files will be stored,

## Outputs

The script generates manifest files that can be committed into ACM unstructured repository.
All generated manifests are generic and apply to all clusters, except `Deployments`.

For `Deployments`, the script generates one manifest per cluster:

* `configsync.gke.io/cluster-name-selector` annotation is used to target given cluster
* Resource name is prefixed with a GKE Hub membership name of a cluster
* Deployment contains container with cluster specific variables

## Authentication

Application default credentials are used to authenticate calls to GCP APIs.

## Usage

```sh
pip install -r requirements.txt
python gke-connect-agent-generator.py -p my-fleet-project-id -d acm-repo
```

## Details

The script uses GKE HUB APIs to list memberships in a fleet and generate Connect Agent manifests:

* `projects.locations.memberships.list`
* `projects.locations.memberships.generateConnectManifest`
