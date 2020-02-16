#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit
IFS=$'\n\t'

TEMPLATE_DIR=${TEMPLATE_DIR:-/tmp/worker}

# Not in the distro repos, so grab the binary from the official GitHub releases
wget -O /usr/bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64'
chmod +x /usr/bin/jq

################################################################################
### Docker #####################################################################
################################################################################

# Enable docker daemon to start on boot.
sudo systemctl daemon-reload
sudo systemctl enable docker

################################################################################
### Kubernetes #################################################################
################################################################################

sudo systemctl daemon-reload
# Disable the kubelet until the proper dropins have been configured
sudo systemctl disable kubelet

################################################################################
### EKS ########################################################################
################################################################################

sudo mkdir -p /etc/eks
sudo touch /etc/eks/solodev.txt
# sudo mv $TEMPLATE_DIR/eni-max-pods.txt /etc/eks/eni-max-pods.txt
sudo mv $TEMPLATE_DIR/bootstrap.sh /etc/eks/bootstrap.sh
sudo chmod +x /etc/eks/bootstrap.sh
