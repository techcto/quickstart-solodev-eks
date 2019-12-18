#!/bin/bash
args=("$@")

#Config
export EKSName="EKS-bkws56uwnMX1"
export ControlPlaneProvisionRoleArn="arn:aws:iam::893612263489:role/eks1-EKSStack-179XIZY9OFZ-ControlPlaneProvisionRol-ZFPQBSXDGCR3"
export KUBECONFIG="eksconfigeks1"

#Node SSH
export KEY="docker1.pem"
export BASTION="3.233.11.21"

#AWS
export REGION="us-east-1"
export USER_ARN="arn:aws:iam::893612263489:user/shawn"
export AWS_PROFILE="docker1"

#Solodev Settings
export RELEASE="solodev-dcx"
export NAMESPACE="solodev-dcx"
export SECRET="BigSecret123"
export PASSWORD="password"
export DBPASSWORD="password"
export DOMAIN="spacedeploy.com"
export REPO="solodev/cms"

#Developer Settings
export DOCKER_REGISTRY_SERVER=docker.io
export DOCKER_USER=techcto
export DOCKER_EMAIL=shawn@digitalus.com
export DOCKER_PASSWORD=vmUvbyPYj6hB

#ADMIN
proxy(){
    kubectl --kubeconfig=$KUBECONFIG port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8080:80
}

token(){
    kubectl --kubeconfig=$KUBECONFIG -n kube-system describe secret $(kubectl --kubeconfig=$KUBECONFIG -n kube-system get secret | grep eks-admin | awk '{print $1}')
}

ls(){
    kubectl --kubeconfig=$KUBECONFIG get pods --all-namespaces   
}

LETTER="c"
iloop(){
    for ((n=151;n<161;n++))
    do
        helm --kubeconfig $KUBECONFIG install --namespace ${NAMESPACE} --name "${LETTER}${n}" charts/${RELEASE} --set solodev.image.repository=${REPO} --set ui.image.repository=${REPO}-apache --set solodev.cname="${DOMAIN}" --set solodev.settings.appSecret=${SECRET} --set solodev.settings.appPassword=${PASSWORD} --set solodev.settings.dbPassword=${DBPASSWORD}
        sleep 2
    done
}

dloop(){
    for ((n=101;n>61;n--))
    do
        helm --kubeconfig $KUBECONFIG del --purge "${LETTER}${n}"
    done
}

install(){
    NAME="${args[1]}"
    helm --kubeconfig $KUBECONFIG install --namespace ${NAMESPACE} --name ${NAME} charts/${RELEASE} --set solodev.image.repository=${REPO} --set ui.image.repository=${REPO}-apache --set solodev.cname="${DOMAIN}" --set solodev.settings.appSecret=${SECRET} --set solodev.settings.appPassword=${PASSWORD} --set solodev.settings.dbPassword=${DBPASSWORD}
}

clear(){
    kubectl --kubeconfig $KUBECONFIG get pods --all-namespaces | grep Evicted | awk '{print $2 " --namespace=" $1}' | xargs kubectl delete pod
}

delete(){
    NAME="${args[1]}"
    helm --kubeconfig $KUBECONFIG del --purge ${NAME}
    kubectl --kubeconfig $KUBECONFIG delete --namespace ${NAME} --all pvc
}

rm(){
#     kubectl --kubeconfig $KUBECONFIG --namespace kube-system delete deployment kubernetes-dashboard
    kubectl --kubeconfig=$KUBECONFIG delete deployments,statefulsets,replicasets --namespace=kube-system stork
}

#UTILS
update(){
    helm --kubeconfig $KUBECONFIG repo add charts 'https://raw.githubusercontent.com/techcto/charts/master/'
    helm --kubeconfig $KUBECONFIG repo update
    helm --kubeconfig $KUBECONFIG repo list
}

log(){
    POD="${args[1]}"
    kubectl --kubeconfig=$KUBECONFIG logs -f $POD
}

clean(){
    NAME="${args[1]}"
    kubectl --kubeconfig $KUBECONFIG delete --all daemonsets,replicasets,statefulsets,services,ingress,deployments,pods,rc,configmap,pvc --namespace=${NAME} --grace-period=0 --force
    #,pv
}

#INIT
init(){
    initConfig
    helm --kubeconfig $KUBECONFIG init
    helm --kubeconfig $KUBECONFIG repo add charts 'https://raw.githubusercontent.com/techcto/charts/master/'
    initSecret
    datadog
}

initConfig(){
    addTrustPolicy
    echo "Sleep for 30 seconds"
    sleep 30
    aws eks --region $REGION update-kubeconfig --name $EKSName --role-arn $ControlPlaneProvisionRoleArn --kubeconfig $KUBECONFIG
}

addTrustPolicy(){
    if [ "$USER_ARN" != "" ]; then
        ROLE_NAME=$(echo $ControlPlaneProvisionRoleArn | awk -F/ '{print $NF}')
        aws iam get-role --role-name ${ROLE_NAME} --profile ${AWS_PROFILE} > role-trust-policy.json
        POLICY='{
        "Effect": "Allow",
        "Principal": {
            "AWS": "'${USER_ARN}'"
        },
        "Action": "sts:AssumeRole"
        }'
        jq --argjson obj "${POLICY}" '.Role.AssumeRolePolicyDocument.Statement += [$obj] | .Role.AssumeRolePolicyDocument' role-trust-policy.json > output-policy.json
        aws iam update-assume-role-policy --role-name ${ROLE_NAME} --policy-document file://output-policy.json --profile ${AWS_PROFILE}
    fi
}

initSSL(){
    #https://docs.cert-manager.io/en/latest/tasks/issuing-certificates/ingress-shim.html
    helm --kubeconfig $KUBECONFIG repo add jetstack https://charts.jetstack.io
    kubectl --kubeconfig=$KUBECONFIG create namespace cert-manager
    kubectl --kubeconfig=$KUBECONFIG label namespace cert-manager certmanager.k8s.io/disable-validation=true
    kubectl --kubeconfig=$KUBECONFIG apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

    #https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/dns01/route53.html
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer
}

initSecret(){
    kubectl --kubeconfig $KUBECONFIG create namespace solodev-dcx
    kubectl --kubeconfig=$KUBECONFIG create secret docker-registry solodev --namespace solodev-dcx \
    --docker-server=$DOCKER_REGISTRY_SERVER \
    --docker-username=$DOCKER_USER \
    --docker-password=$DOCKER_PASSWORD \
    --docker-email=$DOCKER_EMAIL
}

ssh(){
    HOST="${args[1]}"
    echo "ssh -i $KEY  ec2-user@$HOST -o \"proxycommand ssh -W %h:%p -i ${KEY} ec2-user@${BASTION}\""
}

datadog(){
    kubectl --kubeconfig $KUBECONFIG create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrole.yaml"
    kubectl --kubeconfig $KUBECONFIG create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/serviceaccount.yaml"
    kubectl --kubeconfig $KUBECONFIG create -f "https://raw.githubusercontent.com/DataDog/datadog-agent/master/Dockerfiles/manifests/rbac/clusterrolebinding.yaml"
    kubectl --kubeconfig $KUBECONFIG create secret generic datadog-secret --from-literal api-key="eedbadc78b55ca876fea2fd4fdbf7856"
    kubectl --kubeconfig $KUBECONFIG create -f https://raw.githubusercontent.com/techcto/charts/master/solodev-network/templates/datadog-agent.yaml
    # kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/techcto/charts/master/solodev-network/templates/datadog-agent.yaml
}


$*