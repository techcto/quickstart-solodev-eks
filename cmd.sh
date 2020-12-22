#!/bin/bash
args=("$@")

init(){
    # git submodule init
    # git remote add upstream https://github.com/aws-quickstart/quickstart-amazon-eks.git
    git submodule add -f https://github.com/aws-quickstart/quickstart-aws-vpc.git ./submodules/quickstart-aws-vpc
    git submodule add -f https://github.com/aws-quickstart/quickstart-linux-bastion.git ./submodules/quickstart-linux-bastion
    git submodule add -f https://github.com/aws-quickstart/quickstart-amazon-eks-cluster-resource-provider.git ./functions/source/EksClusterResource
    git submodule add -f https://github.com/aws-quickstart/quickstart-helm-resource-provider.git ./functions/source/HelmReleaseResource
    git submodule add -f https://github.com/aws-quickstart/quickstart-eks-snyk.git ./submodules/quickstart-eks-snyk
    git submodule add -f https://github.com/aws-quickstart/quickstart-eks-newrelic-infrastructure.git ./submodules/quickstart-eks-newrelic-infrastructure
    git submodule add -f https://github.com/aws-quickstart/quickstart-kubernetes-resource-provider.git ./functions/source/kubernetesResources
    git submodule add -f https://github.com/aws-quickstart/quickstart-documentation-base-common.git ./docs/boilerplate
    git submodule add -f https://github.com/aws-quickstart/quickstart-amazon-eks-nodegroup.git ./submodules/quickstart-amazon-eks-nodegroup
}

merge() {
    git pull https://github.com/aws-quickstart/quickstart-amazon-eks.git master --allow-unrelated-histories
    git fetch upstream
    git checkout tags/3.0.0
    git merge 3.0.0
}

update(){
    git submodule update
}

build(){
    taskcat test run
}

tag(){
    VERSION="${args[1]}"
    git tag -a v${VERSION} -m "tag release"
    git push --tags
}

clean(){
    for BUCKET in $(aws s3api list-buckets --region us-east-1 | jq -r '.Buckets[].Name')
    do
        if [[ $BUCKET == "tcat-"* ]]; then
            echo "I found one. Time to delete a bucket: ${BUCKET}.  Bye-Bye!"
            # aws s3 rm arn:aws:s3:::$BUCKET --recursive
            aws s3 rb "s3://${BUCKET}" --force 
        fi
    done
}


$*