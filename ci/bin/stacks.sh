#!/usr/bin/env bash

#Params...
CLUSTER=0
MCLUSTER=1

if [ $CLUSTER == 1 ]; then

echo "Create AWS EKS Cluster"
echo $(aws s3 cp s3://build-secure/params/aws-eks-115.json - ) > eks.json
aws cloudformation create-stack --disable-rollback --stack-name tmp-eks-115-${CODEBUILD_BUILD_NUMBER} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/1.15/templates/amazon-eks-master-existing-vpc.template.yaml
fi

if [ $MCLUSTER == 1 ]; then

echo "Create AWS EKS Mega Cluster"
echo $(aws s3 cp s3://build-secure/params/solodev-eks-115.json - ) > eks.json
aws cloudformation create-stack --disable-rollback --stack-name tmp-megaeks-115-${CODEBUILD_BUILD_NUMBER} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/1.15/templates/solodev-eks-master-existing-vpc.template.yaml
fi