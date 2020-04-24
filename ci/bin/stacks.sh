#!/usr/bin/env bash

#Params
CLUSTER=0
MCLUSTER=1

if [ $CLUSTER == 1 ]; then

echo "Create AWS Quickstart EKS Cluster"
echo $(aws s3 cp s3://build-secure/params/aws-eks-114.json - ) > eks.json
aws cloudformation create-stack --disable-rollback --stack-name tmp-eks-114-${CODEBUILD_BUILD_NUMBER} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/1.14/templates/solodev-eks.yaml
fi

if [ $MCLUSTER == 1 ]; then

echo "Create Solodev Managed EKS Cluster"
echo $(aws s3 cp s3://build-secure/params/solodev-eks-114.json - ) > eks.json
aws cloudformation create-stack --disable-rollback --stack-name tmp-megaeks-114-${CODEBUILD_BUILD_NUMBER} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/1.14/templates/solodev-eks.yaml
fi