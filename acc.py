from oscar_python.client import Client
import sys
import json
from requests import HTTPError

""" Using oscar_python library to force the image pull by
    updating the service
"""

SCRIPT_PATH = 'script.sh'
CLUSTER_ENDPOINT = 'https://inference.cloud.ai4eosc.eu'

def get_service_definition(module_name, cpu, memory, image):
    return {
            "cluster_id": "oscar-ai4eosc-cluster",
            "name" : module_name,
            "memory": memory,
            "cpu": cpu,
            "alpine": False,
            "vo": "vo.ai4eosc.eu",
            "image": image,
            "log_level": "CRITICAL",
            "script": read_script(),
            "allowed_users": []
    }

def read_script():
    with open(SCRIPT_PATH) as f:
        return f.read()

args = sys.argv
filename = args[1]

with open(filename) as f:
    service_metadata = json.load(f)

TOKEN = service_metadata["token"]
SERVICE_NAME = service_metadata["metadata"]["title"]

connect_options = {'cluster_id':'oscar-ai4eosc-cluster',
        'endpoint': CLUSTER_ENDPOINT,
        'oidc_token': TOKEN,
        'ssl':'True'}

try:
    oscar_client = Client(options = connect_options)
except ValueError as ve:
    print("[!] Error creating OSCAR client: ", ve)
    exit(1)

try:
    service_exists = oscar_client.get_service(SERVICE_NAME)
    # It's an update on an existing module
    print("[*] Updating service '",SERVICE_NAME,"'")
    service_def = json.loads(service_exists.text)
    # Update CPU, memory or name if changed
    service_def["cpu"] = service_metadata["metadata"]["resources"]["CPU"]
    service_def["memory"] = service_metadata["metadata"]["resources"]["memory"]

    oscar_client.update_service(SERVICE_NAME, service_def)
except HTTPError as e:
    if e.response.status_code == 401:
        print("[!] Error: Unauthorized token")
        exit(1)
    if e.response.status_code == 404:
        # It's a new module
        print("[*] Creating new service '",SERVICE_NAME,"'")
        service_def = get_service_definition(SERVICE_NAME, 
                                            service_metadata["metadata"]["resources"]["CPU"], 
                                            service_metadata["metadata"]["resources"]["memory"], 
                                            service_metadata["metadata"]["sources"]["docker_registry_repo"])
        response = oscar_client.create_service(service_def)

