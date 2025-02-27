# Fargate_Quick-Start

Use this page if you want to deploy Falcon Container Sensor on ECS Fargate environment. This project was intended to help users reduce the effort and complexity of a deployment process.

The script will helps you to automate the deployment of our sidecar by 2 different methods:

Falcon Utility: To patch a container image without the need to interact with Task Definitions;
Patching utility: To patch a task definition without touching the container image.

To get more details about Falcon Container Sensor, it's dependencies and deployment methods, please use our Official Documentation.

Purpose
To facilitate quick deployment of recommended CWP resources.

For other deployment methods including, advanced customization and highly automated deployments, please use our official documentation to help meeting your requirements and needs.

## Prerequisites:
- CrowdStrike API Key Pair created with Falcon Images Download (read) and Sensor Download (read) scopes assigned.
- curl installed
- jq installed
- docker installed
- ECS Cluster name
- ECR repository to store Falcon Container Sensor image (optional).
- AWS Required Permissions

## ECS:
- ecs:ListServices
- ecs:ListTaskDefinitionFamilies
- ecs:DescribeCluster
- ecs:DescribeServices
- ecs:DescribeTaskDeinition
- ecs:RegisterTaskDeinition

## ECR:
- ecr:DescribeRepositories
- ecr:GetAuthorizationToken
- ecr:BatchGetImage
- ecr:CreateRepostiroy

# PATCHING UTILITY - PATCHING TASK DEFINITION

The Falcon patching utility runs offline and takes task definition JSON as an input to generate a new task definition JSON file. The new task definition does 2 things:

Injects crowdstrike-falcon-init-container into each task container.
Makes the Falcon Container sensor the container EntryPoint.


You can have more information on our official documentation.

Prerequisites
CrowdStrike API Key Pair created with Falcon Images Download (read) and Sensor Download (read) scopes assigned.
curl installed
jq installed
docker installed
ECS Cluster name
ECR repository to store Falcon Container Sensor image (optional).
Installation Workflow
manual-patch-utility-task-definition:
1. The script will list all ACTIVE task definition from the region you defined;
2. Type the number representing the task definition you want to patch;
3. You will be asked if you have an existing ECR repository to store falcon container sensor image or if it should create one for you;
4. It will pull the latest image from CrowdStrike's registry and push it to your existing/new ECR repository;
5. Then it will patch your task definition with falcon container sensor information and register the new task definition in your AWS account.
6. The script will also create a local folder containing the original task definition JSON file and the new patched one.

manual-patch-utility-service:
1. The script will list all services running on your ECS cluster;
2. Type the name of the service you want to patch;
3. You will be asked if you have an existing ECR repository to store falcon container sensor image or if it should create one for you;
4. It will pull the latest image from CrowdStrike's registry and push to your existing/new ECR repository;
5. It collects the associated task definition to the chosen service, patch it with falcon container sensor and register the new task definition in your AWS account.
6. The script will also create a local folder containing the original task definition JSON file and the new patched one.

automated-patch-utility-cluster:
1. The script will list and patch all services running on your ECS cluster;
2. You will be asked if you have an existing ECR repository to store falcon container sensor image or if it should create one for you;
3. It will pull the latest image from CrowdStrike's registry and push to your existing/new ECR repository;
4. It collects the associated task definition from each service, patch it with falcon container sensor and register all new tasks definition in your AWS account.
5. The script will also create a local folder containing the original task definition JSON file and the new patched one.

Usage


manual-patch-utility-task-definition
./manual-patch-utility-task-definition.sh -u <client-id> -s <client-secret> -r <aws-region>
 
Required Flags:
    -u, --client-id <FALCON_CLIENT_ID>             Falcon API OAUTH Client ID
    -s, --client-secret <FALCON_CLIENT_SECRET>     Falcon API OAUTH Client Secret
    -r, --region <AWS_REGION>                      AWS Cloud Region [us-east-1, us-west-2, sa-east-1]


manual-patch-utility-service
./manual-patch-utility-service.sh -u <client-id> -s <client-secret> -r <aws-region> -c <ecs-cluster-name>
 
Required Flags:
    -u, --client-id <FALCON_CLIENT_ID>             Falcon API OAUTH Client ID
    -s, --client-secret <FALCON_CLIENT_SECRET>     Falcon API OAUTH Client Secret
    -r, --region <AWS_REGION>                      AWS Cloud Region [us-east-1, us-west-2, sa-east-1]
    -c, --cluster <CLUSTER_NAME>                   ECS Cluster name


automated-patch-utility-cluster
./automated-patch-utility-cluster.sh -u <client-id> -s <client-secret> -r <aws-region> -c <ecs-cluster-name>
 
Required Flags:
    -u, --client-id <FALCON_CLIENT_ID>             Falcon API OAUTH Client ID
    -s, --client-secret <FALCON_CLIENT_SECRET>     Falcon API OAUTH Client Secret
    -r, --region <AWS_REGION>                      AWS Cloud Region [us-east-1, us-west-2, sa-east-1]
    -c, --cluster <CLUSTER_NAME>                   ECS Cluster name

# FALCON UTLITY - PATCHING CONTAINER IMAGE

Deploying the Falcon Container sensor for Linux to ECS Fargate requires modification of the application container image. The Falcon Container sensor image contains a Falcon utility that supports patching the application container image with Falcon Container sensor for Linux and its related dependencies.

The Falcon Container has 2 components:

Falcon Container sensor for Linux: At runtime, the Falcon Container sensor for Linux uses unique technology to launch and run inside the application container of the service or task.
Falcon utility: The Falcon utility runs offline and takes the application container image as an input to generate a new container image patched with the Falcon Container sensor for Linux and its related dependencies. The Falcon utility also sets the Falcon entry point as the container entry point.


You can have more information on our official documentation.

Prerequisites
CrowdStrike API Key Pair created with Falcon Images Download (read) and Sensor Download (read) scopes assigned.
curl installed
jq installed
docker installed
ECS Cluster name
ECR repository to store Falcon Container Sensor image (optional).
Installation Workflow
manual-falcon-utility-task-definition:
1. The script will list all ACTIVE task definition from the region you defined;
2. Type the number representing the task definition you want to patch;
3. You will be asked if you have an existing ECR repository to store falcon container sensor image or if it should create one for you;
4. It will pull the latest image from CrowdStrike's registry and push it to your existing/new ECR repository;
5. The script will collect the container image from the chosen task definition and patch it with Falcon Utility;
6. The new patched image will be pushed to the app container's repository;
7. A new task definition will be created and registered on your AWS account using the new patched image;
8. The script will also create a local folder containing the original task definition JSON file and the new patched one.

manual-falcon-utility-service:
1. The script will list all services running on your ECS cluster;
2. Type the name of the service you want to patch;
3. You will be asked if you have an existing ECR repository to store falcon container sensor image or if it should create one for you;
4. It will pull the latest image from CrowdStrike's registry and push to your existing/new ECR repository;
5. It collects and pulls the associated container image from the chosen service;
6. Patches it with falcon container sensor and push the new image to application's container ECR repository;
7. Creates a new task definition revision containing the new patched image;
8. The script will also create a local folder containing the original task definition JSON file and the new patched one.

Usage
manual-falcon-utility-task-definition
./manual-falcon-utility-task-definition.sh -u <client-id> -s <client-secret> -r <aws-region> -t <custom-grouping-tag>
 
Required Flags:
    -u, --client-id <FALCON_CLIENT_ID>             Falcon API OAUTH Client ID
    -s, --client-secret <FALCON_CLIENT_SECRET>     Falcon API OAUTH Client Secret
    -r, --region <AWS_REGION>                      AWS Cloud Region [us-east-1, us-west-2, sa-east-1]
    -t, --tag <FALCON_TAG>                         Falcon Grouping Tag


manual-falcon-utility-service
./manual-falcon-utility-service.sh -u <client-id> -s <client-secret> -r <aws-region> -c <ecs-cluster-name> -t <custom-grouping-tag>
 
Required Flags:
    -u, --client-id <FALCON_CLIENT_ID>             Falcon API OAUTH Client ID
    -s, --client-secret <FALCON_CLIENT_SECRET>     Falcon API OAUTH Client Secret
    -r, --region <AWS_REGION>                      AWS Cloud Region [us-east-1, us-west-2, sa-east-1]
    -c, --cluster <CLUSTER_NAME>                   ECS Cluster name
    -t, --tag <FALCON_TAG>                         Falcon Grouping Tag

