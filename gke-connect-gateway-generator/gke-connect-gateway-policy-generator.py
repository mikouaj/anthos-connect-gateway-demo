from optparse import OptionParser
import os
import yaml

clusterRoleBindingImpersonateTemplate = """apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gateway-impersonate
roleRef:
  kind: ClusterRole
  name: gateway-impersonate
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: connect-agent-sa
  namespace: gke-connect
"""

parser = OptionParser()
parser.add_option("-u", "--user", dest="users", action="append", help="Users to grant cluster admin rights via Connect Gateway")
parser.add_option("-d", "--directory", dest="directory", help="The local directory to store manifest files")

(options, args) = parser.parse_args()
if options.users is None or options.directory is None: 
    parser.print_help()
    os._exit(os.EX_NOINPUT)

clusterRoleImpersonate = {
    'apiVersion': 'rbac.authorization.k8s.io/v1',
    'kind': 'ClusterRole',
    'metadata': {
        'name': 'gateway-impersonate'
    },
    'rules': [
        {
            'apiGroups': [""],
            'resourceNames': options.users,
            'resources': ['users'],
            'verbs': ['impersonate']
        }
    ]
}

subjects = []
for user in options.users:
    subjects.append({'kind':'User','name':user})

clusterRoleAdmins = {
    'apiVersion': 'rbac.authorization.k8s.io/v1',
    'kind': 'ClusterRoleBinding',
    'metadata': {
        'name': 'gateway-cluster-admin'
    },
    'subjects': subjects,
    'roleRef': {
        'kind': 'ClusterRole',
        'name': 'cluster-admin',
        'apiGroup': 'rbac.authorization.k8s.io'
    }
}

files = [
    {'name':'connect_gateway_clusterrole_gateway-impersonate.yaml', 'content':yaml.dump(clusterRoleImpersonate)},
    {'name':'connect_gateway_clusterrolebinding_gateway-impersonate.yaml', 'content':clusterRoleBindingImpersonateTemplate},
    {'name':'connect_gateway_clusterrolebinding_gateway-cluster-admin.yaml', 'content':yaml.dump(clusterRoleAdmins)}
]

for file in files:
    os.makedirs(options.directory, exist_ok=True)
    f = open('{}/{}'.format(options.directory,file['name']), "w")
    f.write(file['content'])
    f.close()
