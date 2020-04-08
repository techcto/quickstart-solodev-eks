# Deploy Solodev CMS on an EKS Cluster via Custom kubectl commands
The following steps will allow you to deploy Solodev CMS to an existing EKS cluster via a custom set of kubectl commands. Additional installation methods are available including <a href="deploy-solodev-cms.md">via AWS CloudFormation</a> or via <a href="https://github.com/techcto/charts">Helm Charts</a>.

These instructions presume you already have installed <a href="https://helm.sh/">Helm</a>, <a href="https://kubernetes.io/">Kubernetes</a>, and the <a href="https://kubernetes.io/docs/tasks/tools/install-kubectl/">Kubernetes command-line tool</a>.

## Step 1: Subscribe on the AWS Marketplace
Solodev is a professionally managed, enterprise-class Digital Customer Experience Platform and content management system (CMS). Before launching one of our products, you'll first need to subscribe to Solodev on the <a href="https://aws.amazon.com/marketplace/pp/B07XV951M6">AWS Marketplace.</a> Click the button below to get started: 
<table>
	<tr>
		<td width="60%"><a href="https://aws.amazon.com/marketplace/pp/B07XV951M6"><img src="https://raw.githubusercontent.com/solodev/aws/master/pages/images/AWS_Marketplace_Logo.jpg" /></a></td>
		<td><a href="https://aws.amazon.com/marketplace/pp/B07XV951M6"><img src="https://raw.githubusercontent.com/solodev/aws/master/pages/images/Subscribe_Large.jpg" /></a></td>
	</tr>
</table>

## Step 2: Download and Configure kcmd.sh
Access and download the <a href="https://github.com/techcto/quickstart-solodev-eks/blob/master/scripts/kcmd.sh">Solodev EKS custom kcmd.sh script</a>. Place the shell script inside a directory you will use to access your Kubernetes cluster.

Modify lines 8-21 with values specific to your environment. Line 15 corresponds to the region you want to launch within. Lines 8-11 correspond to the values of your Kubernetes cluster, which can be retrieved as <a href="https://raw.githubusercontent.com/solodev/AWS-Launch-Pad/master/pages/images/install/outputs-solodev-cms-eks.jpg">stack outputs</a> if the cluster was launched via CloudFormation. Lines 17-21 correspond to the values used to launch Solodev DCX. 

<pre>
#GET VALUES FROM CLOUDFORMATION OUTPUT OF EKS STACK
export EKSName=""
export ControlPlaneProvisionRoleArn=""

#AWS
export REGION="us-east-1"
export USER_ARN=""
export KEY="server.pem"
export BASTION="1.1.1.1"
#aws configure --profile profile1
export AWS_PROFILE="profile1"

#Solodev
export RELEASE="solodev-dcx-aws"
export NAMESPACE="solodev-dcx"
export SECRET="BigSecret123"
export PASSWORD="password"
export DBPASSWORD="password"
</pre>

## Step 3: Deploy Solodev CMS on your Kubernetes Cluster
From command line and inside the directory that has the kcmd.sh script, run the following to download the necessary Helm Charts and configure a needed config file:
<pre>
./kcmd.sh init
</pre>

From command line and inside the directory that has the kcmd.sh script, run the following to install Solodev CMS:
<pre>
./kcmd.sh install solodev-cms (helm install --namespace solodev-dcx --name CMS1 charts/solodev-dcx)
</pre>

## Step 4: Retrieve the External Endpoints of the "ui" Service
In addition to the other services deployed, Solodev CMS will deploy a "ui" service. This service will output external endpoints that you can use to access Solodev CMS. 

<table>
	<tr>
		<td><img src="https://raw.githubusercontent.com/solodev/AWS-Launch-Pad/master/pages/images/install/eks-external-endpoints.jpg" /></td>
	</tr>
</table>

## Step 5: Login to Solodev 
Visit the external endpoint retrived in step 4 to load Solodev CMS. Use the the username "solodev" and the PASSWORD specified during step 2 for login credentials.

<table>
	<tr>
		<td><img src="https://raw.githubusercontent.com/solodev/AWS-Launch-Pad/master/pages/images/install/login-solodev-cms-eks.jpg" /></td>
	</tr>
</table>

---
© 2020 Solodev. All rights reserved worldwide. And off planet. 

Errors or corrections? Email us at help@solodev.com.

---
Visit [solodev.com](https://www.solodev.com/) to learn more. <img src="https://www.google-analytics.com/collect?v=1&tid=UA-3849724-1&cid=1&t=event&ec=github_aws&ea=main&cs=github&cm=github&cn=github_aws" />