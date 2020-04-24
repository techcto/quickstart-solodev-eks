#!/usr/bin/env bash

#echo $(aws cloudformation describe-stacks)
for BUCKET in $(aws s3api list-buckets --region us-east-1 | ./jq -r '.Buckets[].Name')
do
    if [[ $BUCKET == "tmp-eks-"* ]]; then
        echo "I found one. Time to delete a bucket: ${BUCKET}.  Bye-Bye!"
        aws s3 rb s3://$BUCKET --force 
    fi
    if [[ $BUCKET == "tmp-megaeks-"* ]]; then
        echo "I found one. Time to delete a bucket: ${BUCKET}.  Bye-Bye!"
        aws s3 rb s3://$BUCKET --force 
    fi
done

for STACK in $(aws cloudformation describe-stacks --region us-east-1 | ./jq -r '.Stacks[].StackName')
do
    if [[ $STACK == "tmp-eks-"* ]]; then
        echo "I found one. Time to delete stack: ${STACK}.  Bye-Bye!"
        aws cloudformation delete-stack --stack-name $STACK
    fi
    if [[ $STACK == "tmp-megaeks-"* ]]; then
        echo "I found one. Time to delete stack: ${STACK}.  Bye-Bye!"
        aws cloudformation delete-stack --stack-name $STACK
    fi
done