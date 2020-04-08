#!/usr/bin/env bash

#Params
CLUSTER=0
MEGACLUSTER=0
DEPLOYMENT=0
MPDEPLOYMENT=0

if [ $CLUSTER == 1 ]; then

echo "Create AWS EKS Cluster"
echo $(aws s3 cp s3://build-secure/params/amazon-eks.json - ) > amazon-eks.json
aws cloudformation create-stack --disable-rollback --stack-name eks-tmp-${DATE} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/amazon-eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/templates/solodev-eks.yaml \
    # --notification-arns $NOTIFICATION_ARN

fi

if [ $MEGACLUSTER == 1 ]; then

echo "Create AWS EKS Mega Cluster"
echo $(aws s3 cp s3://build-secure/params/amazon-eks-mega.json - ) > amazon-eks.json
aws cloudformation create-stack --disable-rollback --stack-name eksmega-${DATE} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/amazon-eks.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/templates/solodev-eks.yaml \
    # --notification-arns $NOTIFICATION_ARN

fi

if [ $DEPLOYMENT == 1 ]; then

echo "Install Solodev DCX"
echo $(aws s3 cp s3://build-secure/params/solodev-dcx.json - ) > solodev-dcx.json
aws cloudformation create-stack --disable-rollback --stack-name solo-${DATE} --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/solodev-dcx.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/templates/solodev-cms.yaml \
    # --notification-arns $NOTIFICATION_ARN

fi

if [ $MPDEPLOYMENT == 1 ]; then

echo "Install Solodev DCX for Marketplace"
echo $(aws s3 cp s3://build-secure/params/solodev-dcx.json - ) > solodev-dcx.json
aws cloudformation create-stack --disable-rollback --stack-name solo-${DATE}mp --disable-rollback --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --parameters file:///${CODEBUILD_SRC_DIR}/solodev-dcx.json \
    --template-url https://s3.amazonaws.com/solodev-quickstarts/eks/templates/solodev-cms-aws.yaml \
    # --notification-arns $NOTIFICATION_ARN

fi