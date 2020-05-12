# Deploy Kubernetes Web UI (Dashboard) via CloudFormation
The following steps will allow you to deploy Kubernetes Web UI (Dashboard) to an existing EKS cluster by launching a new stack via AWS CloudFormation.

## Step 1: Launch your CloudFormation Stack
<p align="center"><a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=kubernetes-dashboard&templateURL=https://solodev-quickstarts.s3.amazonaws.com/eks/1.15/templates/solodev-eks-dashboard.template.yaml"><img src="https://raw.githubusercontent.com/solodev/aws/master/pages/images/solodev-launch-btn.png" width="200" /></a></p>

## Step 2: Fill Out the CloudFormation Stack Wizard
<strong>Continue with the preselected CloudFormation Template</strong><br />
The Amazon S3 template URL (used for the CloudFormation configuration) should be preselected. Click "Next" to continue.

<strong>Specify Details</strong><br />
The following parameters must be configured to launch your Solodev Managed Kubernetes for EKS CloudFormation stack:

---
© 2020 Solodev. All rights reserved worldwide. And off planet. 

Errors or corrections? Email us at help@solodev.com.

---
Visit [solodev.com](https://www.solodev.com/) to learn more. <img src="https://www.google-analytics.com/collect?v=1&tid=UA-3849724-1&cid=1&t=event&ec=github_aws&ea=main&cs=github&cm=github&cn=github_aws" />
