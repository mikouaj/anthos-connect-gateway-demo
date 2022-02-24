# gke-connect-gateway-generator

GKE Connect Gateway Generator is a script that generates K8S manifests with
`ClusterRole` and `ClusterRoleBinding` objects required for cluster authentication via
[GKE Connect Gateway](https://cloud.google.com/anthos/multicluster-management/gateway/setup).

## Inputs

The scripts takes the following input arguments:

* `-u` `--user` *(Required)* one or more users that will be 
* `-d` `--directory` *(Required)* the output directory where generated manifest files will be stored

## Outputs

The script generates manifest files that can be committed into ACM unstructured repository.

## Usage

```sh
pip install -r requirements.txt
python gke-connect-gateway-generator.py -u john@mydomian.com -u jane@mydomain.com -d acm-repo
```
