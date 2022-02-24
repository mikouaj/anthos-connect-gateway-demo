from google.cloud import gkehub_v1
from optparse import OptionParser
import os
import yaml

class GkeFleetMembersNotFound(Exception):
    pass

class GkeFleet:
    def __init__(self, project, directory):
        self.project = project
        self.directory = directory
        self.fileNamePrefix = "connect-agent"
        self.client = gkehub_v1.GkeHubClient()

    def getMemberships(self):
        resp = self.client.list_memberships(request={'parent':'projects/{}/locations/global'.format(self.project)}) 
        return list(map(lambda membership: {'name':membership.name,'cluster':membership.endpoint.gke_cluster.resource_link}, resp))

    def _getSecretManifest(self):
        secret = {
            'apiVersion': 'v1',
            'kind': 'Secret',
            'metadata': {
                'name': 'creds-gcp',
                'namespace': 'gke-connect'
            },
            'data': {
                'creds-gcp.json':''
            }
        }
        return {'name':'connect_agent_secret_creds-gcp.yaml', 'content':secret, 'directory':self.directory}

    def _getDeploymentFile(self, membership, manifest):
        clusterName = membership['cluster'].split('/')[-1]
        memberShipName = membership['name'].split('/')[-1]
        manifest['metadata']['annotations']['configsync.gke.io/cluster-name-selector'] = clusterName
        manifest['metadata']['name'] = "{}-{}".format(memberShipName,manifest['metadata']['name']) 
        fileName = 'connect_agent_deployment_{}.yaml'.format(memberShipName)
        return {'name':fileName, 'content':manifest, 'directory': self.directory}

    def _getGenericFile(self, manifest):
        fileName = 'connect_agent_{}_{}.yaml'.format(manifest['kind'].lower(),manifest['metadata']['name'])
        return {'name':fileName, 'content':manifest, 'directory': self.directory}

    def getManifests(self):
        memberships = self.getMemberships()
        if len(memberships) < 1:
            raise GkeFleetMembersNotFound()
        files = {}
        for membership in memberships:
            resp = self.client.generate_connect_manifest(request={"name":membership['name']})
            for manifest in resp.manifest:
                manifestYaml = yaml.safe_load(manifest.manifest)
                if manifestYaml['kind'].lower() == 'deployment':
                    file = self._getDeploymentFile(membership, manifestYaml)
                else:
                    file = self._getGenericFile(manifestYaml)

                files[file['name']] = file

        secFile = self._getSecretManifest()
        files[secFile['name']] = secFile
        return list(files.values())

parser = OptionParser()
parser.add_option("-p", "--project", dest="project", help="The GKE fleet host project")
parser.add_option("-d", "--directory", dest="directory", help="The local directory to store manifest files")

(options, args) = parser.parse_args()
if options.project is None or options.directory is None: 
    parser.print_help()
    os._exit(os.EX_NOINPUT)

fleet = GkeFleet(options.project, options.directory)
for file in fleet.getManifests():
    os.makedirs(file['directory'], exist_ok=True)
    f = open('{}/{}'.format(file['directory'],file['name']), "w")
    f.write(yaml.dump(file['content']))
    f.close()
