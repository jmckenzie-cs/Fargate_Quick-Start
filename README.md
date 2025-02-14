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
