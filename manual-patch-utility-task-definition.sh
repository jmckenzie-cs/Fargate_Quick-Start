#!/bin/bash

set -e

# Function to display usage information
usage() {
    echo "Usage: $0 -r <region> -u <falcon-client-id> -s <falcon-client-secret>"
    echo "  -r: AWS region (required)"
    echo "  -u: CrowdStrike falcon client ID (required)"
    echo "  -s: CrowdStrike falcon client secret (required)"
    exit 1
}

# Check if JQ is installed.
if ! command -v jq &> /dev/null
then
    echo "JQ could not be found."
    exit
fi

# Check if curl is installed.
if ! command -v curl &> /dev/null
then
    echo "curl could not be found."
    exit
fi

# Check if docker is installed.
if ! command -v docker &> /dev/null; then
then
    echo "Docker is not installed. Please install Docker and try again."
    exit
fi

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error occurred: $error_message" >&2
    echo "$error_message" > $task_def_name/error.txt
    exit 1
}

# Function to remove managed parameters from original task definition
remove_keys() {
    local json_file="$1"
    local temp_file="${json_file}.temp"

    jq 'del(.requiresAttributes, 
             .status, 
             .revision, 
             .compatibilities, 
             .registeredAt, 
             .registeredBy, 
             .taskDefinitionArn, 
             if .tags == [] then .tags else empty end)' "$json_file" > "$temp_file"

    mv "$temp_file" "$json_file"
}

# Function to check if a repository exists
check_repository_exists() {
    aws ecr describe-repositories --repository-names "$repository_name" --region $region >/dev/null 2>&1
    return $?
}

# Function to create a repository
create_repository() {
    aws ecr create-repository --repository-name "$repository_name" --region $region >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Repository $1 created successfully."
    else
        echo "Failed to create repository $1."
        exit 1
    fi
}

set -e
trap 'handle_error "An error occurred at line $LINENO"' ERR

# Parse command line arguments
while getopts ":r:c:u:s:" opt; do
    case $opt in
        r) region="$OPTARG" ;;
        c) cluster_name="$OPTARG" ;;
        u) falcon_client_id="$OPTARG" ;;
        s) falcon_client_secret="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
    esac
done

# Initialize variables
region="$region"


# Main code
{

    # List all task definition families
    task_families=$(aws ecs list-task-definition-families --region $region --status ACTIVE --output text --query 'families[*]')

    # Get the latest version of each task definition family
    for family in $task_families; do
        latest=$(aws ecs describe-task-definition --task-definition "$family" --region $region --query 'taskDefinition.taskDefinitionArn' --output text)
        latest_task_definitions+=("$latest")
    done

    # Display task definitions with numbers, one per line
    echo "Available task definitions (latest versions):"
    for i in "${!latest_task_definitions[@]}"; do
        echo "$((i+1)). ${latest_task_definitions[$i]}"
    done
    echo ""
    # Ask user to select a task definition
    read -p "Enter the number of the task definition you want to export: " selection

    # Validate user input
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#latest_task_definitions[@]}" ]; then
        echo "Invalid selection. Exiting."
        exit 1
    fi

    # Get selected task definition
    selected_task_def="${latest_task_definitions[$((selection-1))]}"

    # Extract task definition name
    task_def_name=$(basename "$selected_task_def" | cut -d':' -f1)

    # Create output directory to store task definitions configurations
    mkdir -p "$task_def_name"
    echo ""

    ORIGINAL_TASK_DEFINITION=$task_def_name/${task_def_name}.json

    # Get task definition details and save to JSON file
    aws ecs describe-task-definition --task-definition "$task_def_name" --region $region --query 'taskDefinition' --output json > "$ORIGINAL_TASK_DEFINITION"

    echo "Original task definition exported to $ORIGINAL_TASK_DEFINITION"

    echo "Removing managed parameters from $ORIGINAL_TASK_DEFINITION before patching"

    # Remove specified keys/attributes from json configuration file and save to a temp file
    cleaned_file="$task_def_name/${task_def_name}-cleaned.json"
    cp "$ORIGINAL_TASK_DEFINITION" "$cleaned_file"
    remove_keys "$cleaned_file"

    echo "Cleaned task definition and saved to $cleaned_file"

    # Variables
    export FALCON_CLIENT_ID=$falcon_client_id
    export FALCON_CLIENT_SECRET=$falcon_client_secret
    export FALCON_CID=$(bash <(curl -Ls https://github.com/CrowdStrike/falcon-scripts/releases/latest/download/falcon-container-sensor-pull.sh) -t falcon-container --get-cid)
    export LATESTSENSOR=$(bash <(curl -Ls https://github.com/CrowdStrike/falcon-scripts/releases/latest/download/falcon-container-sensor-pull.sh) -t falcon-container | tail -1)
    export FALCON_IMAGE_TAG=$(echo $LATESTSENSOR | cut -d':' -f 2)
    export ACCOUNT_ID=$(aws ecs describe-task-definition --task-definition "$task_def_name" --region $region --query 'taskDefinition.taskDefinitionArn' --output text | awk -F: '{print $5}')
    export JSON_STRING=$(cat $cleaned_file)

    echo ""
    read -p "Do you have an existing AWS ECR repository for Falcon Container Sensor (yes/no)? " has_repo

    if [ "$has_repo" = "yes" ] || [ "$has_repo" = "y" ]|| [ "$has_repo" = "Yes" ] || [ "$has_repo" = "Y" ]; then

        # List all task definition families
        ecr_repositories_list=$(aws ecr describe-repositories --region $region --query 'repositories[*].repositoryName' --output text)


        # Get the latest version of each task definition family
        for repo in $ecr_repositories_list; do
            ecr_repositories+=("$repo")
        done

        # Display task definitions with numbers, one per line
        echo "Available ECR registries:"
        for i in "${!ecr_repositories[@]}"; do
            echo "$((i+1)). ${ecr_repositories[$i]}"
        done
        echo ""
        # Ask user to select falcon container sensor ECR repo
        read -p "Enter the number of the ECR repository used for Falcon Container Sensor: " selection

        # Validate user input
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#ecr_repositories[@]}" ]; then
            echo "Invalid selection. Exiting."
            exit 1
        fi

        # Get selected task definition
        repo_name="${ecr_repositories[$((selection-1))]}"

    else
        repo_name="falcon-sensor/falcon-container"
        echo "Checking if repository $repo_name exists..."
        if check_repository_exists "$repo_name"; then
            echo "Repository $repo_name already exists."
        else
            echo "Creating repository $repo_name..."
            create_repository "$repo_name"
        fi
    fi

    # Set the new image repo as a variable
    export AWS_REPO=$(aws ecr describe-repositories --repository-name $repo_name --region $region | jq -r  '.repositories[].repositoryUri')
    ECR_LOGIN=$(aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$region.amazonaws.com)

    # tag and push container sensor to your falcon registry
    echo "Pushing latest falcon container sensor image to $repo_name"
    docker tag "$LATESTSENSOR" "$AWS_REPO":"$FALCON_IMAGE_TAG"
    docker push "$AWS_REPO":"$FALCON_IMAGE_TAG"


    echo "Patching Task Definition $task_def_name with Falcon Container Sensor"

    ARCH=$(uname -m)
    if [ "$ARCH" == "arm64" ]; then
        export IMAGE_PULL_TOKEN=$(echo "{\"auths\":{\"${ACCOUNT_ID}.dkr.ecr.${region}.amazonaws.com\":{\"auth\":\"$(echo AWS:$(aws ecr get-login-password --region ${region})|base64 )\"}}}" | base64)
        docker run --platform linux/amd64 \
        --rm "$AWS_REPO":"$FALCON_IMAGE_TAG" \
        -cid $FALCON_CID \
        -image "$AWS_REPO":"$FALCON_IMAGE_TAG" \
        -pulltoken $IMAGE_PULL_TOKEN \
        -ecs-spec "$JSON_STRING" > $task_def_name/${task_def_name}-patched.json
    else
        export IMAGE_PULL_TOKEN=$(echo "{\"auths\":{\"${ACCOUNT_ID}.dkr.ecr.${region}.amazonaws.com\":{\"auth\":\"$(echo AWS:$(aws ecr get-login-password --region ${region})|base64 -w 0)\"}}}" | base64 -w 0)
        docker run --platform linux \
        --rm "$AWS_REPO":"$FALCON_IMAGE_TAG" \
        -cid $FALCON_CID \
        -image "$AWS_REPO":"$FALCON_IMAGE_TAG" \
        -pulltoken $IMAGE_PULL_TOKEN \
        -ecs-spec "$JSON_STRING" > $task_def_name/${task_def_name}-patched.json
    fi

    echo "A new task definition revision has been created and saved on: $task_def_name/${task_def_name}-patched.json created"

    rm -f $cleaned_file

    echo "Registering patched task definition on AWS"
    task_register=$(aws ecs register-task-definition --region $region --cli-input-json file://$task_def_name/${task_def_name}-patched.json)

} || handle_error "Failed to update task definition"