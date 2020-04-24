#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR

IFS=$'\n\t'

function print_help {
    echo "usage: $0 [options] <cluster-name>"
    echo "Bootstraps an instance into an EKS cluster"
    echo ""
    echo "-h,--help print this help"
    echo "--use-max-pods Sets --max-pods for the kubelet when true. (default: true)"
    echo "--b64-cluster-ca The base64 encoded cluster CA content. Only valid when used with --apiserver-endpoint. Bypasses calling \"aws eks describe-cluster\""
    echo "--apiserver-endpoint The EKS cluster API Server endpoint. Only valid when used with --b64-cluster-ca. Bypasses calling \"aws eks describe-cluster\""
    echo "--kubelet-extra-args Extra arguments to add to the kubelet. Useful for adding labels or taints."
    echo "--solodev-network Enable Solodev network settings (default: false)."
}

POSITIONAL=()

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            print_help
            exit 1
            ;;
        --use-max-pods)
            USE_MAX_PODS="$2"
            shift
            shift
            ;;
        --b64-cluster-ca)
            B64_CLUSTER_CA=$2
            shift
            shift
            ;;
        --apiserver-endpoint)
            APISERVER_ENDPOINT=$2
            shift
            shift
            ;;
        --kubelet-extra-args)
            KUBELET_EXTRA_ARGS=$2
            shift
            shift
            ;;
        --enable-weave)
            ENABLE_WEAVE=$2
            shift
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done

set +u
set -- "${POSITIONAL[@]}" # restore positional parameters
CLUSTER_NAME="$1"
set -u

USE_MAX_PODS="${USE_MAX_PODS:-true}"
B64_CLUSTER_CA="${B64_CLUSTER_CA:-}"
APISERVER_ENDPOINT="${APISERVER_ENDPOINT:-}"
KUBELET_EXTRA_ARGS="${KUBELET_EXTRA_ARGS:-}"
ENABLE_WEAVE="${ENABLE_WEAVE:-false}"

if [ -z "$CLUSTER_NAME" ]; then
    echo "CLUSTER_NAME is not defined"
    exit  1
fi

ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_DEFAULT_REGION=$(echo $ZONE | awk '{print substr($0, 1, length($0)-1)}')

### kubelet kubeconfig

CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
if [[ -z "${B64_CLUSTER_CA}" ]] && [[ -z "${APISERVER_ENDPOINT}" ]]; then
    DESCRIBE_CLUSTER_RESULT="/tmp/describe_cluster_result.txt"
    aws eks describe-cluster \
        --region=${AWS_DEFAULT_REGION} \
        --name=${CLUSTER_NAME} \
        --output=text \
        --query 'cluster.{certificateAuthorityData: certificateAuthority.data, endpoint: endpoint}' > $DESCRIBE_CLUSTER_RESULT
    B64_CLUSTER_CA=$(cat $DESCRIBE_CLUSTER_RESULT | awk '{print $1}')
    APISERVER_ENDPOINT=$(cat $DESCRIBE_CLUSTER_RESULT | awk '{print $2}')
fi

echo $B64_CLUSTER_CA | base64 -d > $CA_CERTIFICATE_FILE_PATH

sed -i s,CLUSTER_NAME,$CLUSTER_NAME,g /var/lib/kubelet/kubeconfig
kubectl config \
    --kubeconfig /var/lib/kubelet/kubeconfig \
    set-cluster \
    kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --server=$APISERVER_ENDPOINT

### kubelet.service configuration

MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ -s | head -n 1)
CIDRS=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-ipv4-cidr-blocks)
TEN_RANGE=$(echo $CIDRS | grep -c '^10\..*' || true )
DNS_CLUSTER_IP=10.100.0.10
if [[ "$TEN_RANGE" != "0" ]] ; then
    DNS_CLUSTER_IP=172.20.0.10;
fi

KUBELET_CONFIG=/etc/kubernetes/kubelet/kubelet-config.json
echo "$(jq .clusterDNS=[\"$DNS_CLUSTER_IP\"] $KUBELET_CONFIG)" > $KUBELET_CONFIG

INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)

if [[ "$USE_MAX_PODS" = "true" ]]; then
    MAX_PODS_FILE="/etc/eks/eni-max-pods.txt"
    set +o pipefail
    MAX_PODS=$(grep ^$INSTANCE_TYPE $MAX_PODS_FILE | awk '{print $2}')
    set -o pipefail
    if [[ "$ENABLE_WEAVE" = "true" ]]; then
        MAX_PODS=$(($MAX_PODS*5))
    fi
    if [[ -n "$MAX_PODS" ]]; then
        echo "$(jq ".maxPods=$MAX_PODS" $KUBELET_CONFIG)" > $KUBELET_CONFIG
    else
        echo "No entry for $INSTANCE_TYPE in $MAX_PODS_FILE. Not setting max pods for kubelet"
    fi
fi

if [[ $(ec2-metadata --instance-type) =~ 'large' ]]; then
    mem_reserved=1Gi
else
    mem_reserved=0.5Gi
fi

## Kube network optimisation.
cat <<EOF > /etc/sysctl.d/99-kube-net.conf
# Have a larger connection range available
net.ipv4.ip_local_port_range=1024 65000
 
# Reuse closed sockets faster
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
 
# The maximum number of "backlogged sockets".  Default is 128.
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096
 
# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
net.core.rmem_max=16777216
net.core.wmem_max=16777216
 
# Various network tunables
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216
#vm.min_free_kbytes=65536
 
# Connection tracking to prevent dropped connections (usually issue on LBs)
net.netfilter.nf_conntrack_max=262144
net.ipv4.netfilter.ip_conntrack_generic_timeout=120
net.netfilter.nf_conntrack_tcp_timeout_established=86400
 
# ARP cache settings for a highly loaded docker swarm
net.ipv4.neigh.default.gc_thresh1=8096
net.ipv4.neigh.default.gc_thresh2=12288
net.ipv4.neigh.default.gc_thresh3=16384
EOF
 
systemctl restart systemd-sysctl.service

# ## DNS change to limit the 'search' path
# echo "; generated by bootstrap.sh" > /var/lib/kubelet/resolv.conf

KUBELET_EXTRA_ARGS="${KUBELET_EXTRA_ARGS} --feature-gates CSINodeInfo=true,CSIDriverRegistry=true,CSIBlockVolume=true --kube-reserved cpu=250m,memory=${mem_reserved},ephemeral-storage=1Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%"

cat <<EOF > /etc/systemd/system/kubelet.service.d/10-kubelet-args.conf
[Service]
Environment='KUBELET_ARGS=--node-ip=$INTERNAL_IP --pod-infra-container-image=602401143452.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/eks/pause-amd64:3.1'
EOF

if [[ -n "$KUBELET_EXTRA_ARGS" ]]; then
    cat <<EOF > /etc/systemd/system/kubelet.service.d/30-kubelet-extra-args.conf
[Service]
Environment='KUBELET_EXTRA_ARGS=$KUBELET_EXTRA_ARGS'
EOF
fi

if [[ "$ENABLE_WEAVE" = "true" ]]; then
    rm -Rf /etc/cni/net.d/10-aws.conflist /opt/cni/bin/aws-cni
fi

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
