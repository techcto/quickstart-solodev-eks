import json
import logging
import boto3
import subprocess
import shlex
from crhelper import CfnResource

logger = logging.getLogger(__name__)
helper = CfnResource(json_logging=True, log_level='DEBUG')

try:
    s3_client = boto3.client('s3')
    kms_client = boto3.client('kms')
except Exception as init_exception:
    helper.init_failure(init_exception)


def run_command(command):
    try:
        print("executing command: %s" % command)
        output = subprocess.check_output(shlex.split(command), stderr=subprocess.STDOUT).decode("utf-8")
        print(output)
    except subprocess.CalledProcessError as exc:
        print("Command failed with exit code %s, stderr: %s" % (exc.returncode, exc.output.decode("utf-8")))
        raise Exception(exc.output.decode("utf-8"))
    return output

def create_kubeconfig(cluster_name):
    run_command(f"aws eks update-kubeconfig --name {cluster_name} --alias {cluster_name}")
    run_command(f"kubectl config use-context {cluster_name}")

def enable_weave(cluster_name):
    logger.debug(run_command("kubectl delete ds aws-node -n kube-system"))
    subprocess.check_output("curl --location -o /tmp/weave-net.yaml \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')\"", shell=True)
    logger.debug(run_command("kubectl apply -f /tmp/weave-net.yaml"))

def enable_marketplace(cluster_name, namespace):
    logger.debug(run_command("kubectl create sa aws-serviceaccount --namespace ${namespace}"))
    logger.debug(run_command("kubectl annotate sa aws-serviceaccount eks.amazonaws.com/role-arn=$(aws iam get-role --role-name aws-usage-${cluster_name} --query Role.Arn --output text) --namespace ${namespace}"))

def get_token():
    token=subprocess.check_output("kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')", shell=True)
    return token

def enable_dashboard(cluster_name):
    DOWNLOAD_VERSION="v0.3.6"
    logger.debug(run_command(f"curl -Ls https://api.github.com/repos/kubernetes-sigs/metrics-server/tarball/{DOWNLOAD_VERSION} -o /tmp/metrics-server-{DOWNLOAD_VERSION}.tar.gz"))
    logger.debug(run_command(f"ls -al /tmp"))
    logger.debug(run_command(f"mkdir -p /tmp/metrics-server-{DOWNLOAD_VERSION}"))
    logger.debug(run_command(f"tar -xzf /tmp/metrics-server-{DOWNLOAD_VERSION}.tar.gz --directory /tmp/metrics-server-{DOWNLOAD_VERSION} --strip-components 1"))
    logger.debug(run_command(f"ls -al /tmp/metrics-server-{DOWNLOAD_VERSION}"))
    logger.debug(run_command(f"kubectl apply -f /tmp/metrics-server-{DOWNLOAD_VERSION}/deploy/1.8+/"))
    logger.debug(run_command("kubectl get deployment metrics-server -n kube-system"))
    logger.debug(run_command("kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/alternative.yaml"))
    logger.debug(run_command("kubectl apply -f https://raw.githubusercontent.com/techcto/charts/master/solodev-network/templates/admin-role.yaml"))
    logger.debug(run_command("kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts;"))

@helper.create
@helper.update
def create_handler(event, _):
    print('Received event: %s' % json.dumps(event))
    create_kubeconfig(event['ResourceProperties']['ClusterName'])
    response_data = {}
    if 'Weave' in event['ResourceProperties'].keys():
        enable_weave(event['ResourceProperties']['ClusterName'])
    if 'Dashboard' in event['ResourceProperties'].keys():
        enable_dashboard(event['ResourceProperties']['ClusterName'])
    if 'MarketPlace' in event['ResourceProperties'].keys():
        enable_marketplace(event['ResourceProperties']['ClusterName'], event['ResourceProperties']['Namespace'])
    if 'AccessToken' in event['ResourceProperties'].keys():
        helper.Data['Token'] = get_token()

def lambda_handler(event, context):
    helper(event, context)
