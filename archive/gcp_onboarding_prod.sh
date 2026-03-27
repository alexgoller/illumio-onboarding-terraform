#!/bin/bash

#Constants
RESOURCE_TYPE_PROJECT="project"
RESOURCE_TYPE_ORGANIZATION="organization"
RESOURCE_TYPE_FOLDER="folder"
DEFAULT_ROLE_NAME="illumio_role_$(date +%s)"
DEFAULT_SA_NAME="illumio-sa-$(date +%s)"
DEFAULT_SA_DISPLAY_NAME="Illumio Service Account"
DEFAULT_POST_URL="https://cloud.illum.io"
PREDEFINED_ROLES="roles/iam.securityReviewer,roles/compute.viewer,roles/cloudasset.viewer"
DEFAULT_WRITE_ROLE_NAME="illumio_write_role_$(date +%s)"
WRITE_PERMISSIONS="compute.firewalls.create,compute.firewalls.delete,compute.firewalls.get,compute.firewalls.update,compute.networks.updatePolicy"
DEFAULT_API_ENABLE_ROLE_NAME="illumio_api_enable_role_$(date +%s)"
API_ENABLE_PERMISSION="serviceusage.services.enable,serviceusage.services.list,serviceusage.services.get"

ILLUMIO_SA_EMAIL="illumio-onboarding@cs-prod-01.iam.gserviceaccount.com"

GREEN='\033[32m'
RESET='\033[0m'
RED='\033[31m'

# Resource tracking
created_resources__service_accounts=""
created_resources__roles=""
RESOURCE_TYPE="$RESOURCE_TYPE_PROJECT" # using default resource type as object, based on if organization id is passed in arguments, it changes to "$RESOURCE_TYPE_ORGANIZATION"

# Function to add a resource to the tracking list - these lists will be used to clean up resources in case of an error
add_resource() {
    local resource_type=$1
    local resource_value=$2
    local var_name="created_resources__${resource_type}"
    if [[ -z "${!var_name}" ]]; then
        eval "$var_name=\"$resource_value\""
    else
        eval "$var_name=\"${!var_name},$resource_value\""
    fi
}

# Cleanup function for errors (triggered by trap)
cleanup() {
    if [ "$1" == "0" ]; then
        return
    fi
    echo -e "${RED}Cleaning up resources...${RESET}"

    # Delete service accounts
    IFS=',' read -ra SAS <<< "${created_resources__service_accounts}"
    for sa in "${SAS[@]}"; do
        echo -e "${RED}Deleting service account: $sa${RESET}"
        if ! gcloud iam service-accounts delete "$sa" --quiet --project="$PROJECT_ID"; then
            echo -e "${RED}Failed to delete service account: $sa${RESET}"
        fi
    done

    # Delete roles
    IFS=',' read -ra ROLES <<< "${created_resources__roles}"
    for role in "${ROLES[@]}"; do
        echo -e "${RED}Deleting IAM role: $role${RESET}"
        if [ "$RESOURCE_TYPE" == "$RESOURCE_TYPE_ORGANIZATION" ]; then
            if ! gcloud iam roles delete "$role" --organization="$ORGANIZATION_ID" --quiet; then
                echo -e "${RED}Failed to delete IAM role: $role${RESET}"
            fi
        else
            if ! gcloud iam roles delete "$role" --project="$PROJECT_ID" --quiet; then
                echo -e "${RED}Failed to delete IAM role: $role${RESET}"
            fi
        fi
    done
    echo -e "${GREEN}DONE${RESET}"
}

# Error handling setup
set -e
trap 'cleanup $?' EXIT

print_usage() {
    echo "Usage: $0 --project-id PROJECT_ID --auth-key AUTH_KEY --auth-secret AUTH_SECRET --tenant-id CS_TENANT_ID  [--organization-id ORGANIZATION_ID] [--read-write] [--role-name ROLE_NAME] [--sa-name SA_NAME] [--sa-display-name SA_DISPLAY_NAME] [--illumio-sa-email ILLUMIO_SA_EMAIL] [--post-url POST_URL]"
    echo "  --project-id PROJECT_ID             Specify the GCP project ID (mandatory)"
    echo "  --post-url POST_URL                 Specify the POST URL (optional)"
    echo "  --role-name ROLE_NAME               Specify the role name (optional)"
    echo "  --sa-name SA_NAME                   Specify the service account name (optional)"
    echo "  --sa-display-name SA_DISPLAY_NAME   Specify the service account display name (optional)"
    echo "  --illumio-sa-email ILLUMIO_SA_EMAIL Specify the Illumio service account email (optional)"
    echo "  --auth-key AUTH_KEY                 Specify the authentication key for basic auth to Illumio endpoint (mandatory)"
    echo "  --auth-secret AUTH_SECRET           Specify the authentication secret for basic auth Illumio endpoint (mandatory)"
    echo "  --tenant-id CS_TENANT_ID            Specify the tenant ID for HTTP requests (mandatory)"
    echo "  --organization-id ORGANIZATION_ID   Specify the GCP organization ID (optional)"
    echo "  --folder-id FOLDER_ID               Specify the GCP folder ID (optional)"
    echo "  --read-write                        Enable read-write mode (optional)"
    exit 1
}


# Parse arguments
READ_WRITE_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-id) PROJECT_ID="$2"; shift 2 ;;
        --post-url) POST_URL="$2"; shift 2 ;;
        --role-name) ROLE_NAME="$2"; shift 2 ;;
        --sa-name) SA_NAME="$2"; shift 2 ;;
        --sa-display-name) SA_DISPLAY_NAME="$2"; shift 2 ;;
        --illumio-sa-email) ILLUMIO_SA_EMAIL="$2"; shift 2 ;;
        --organization-id) ORGANIZATION_ID="$2"; shift 2 ;;
        --folder-id) FOLDER_ID="$2"; shift 2 ;;
        --read-write) READ_WRITE_MODE=true; shift ;;
        --auth-key) AUTH_KEY="$2"; shift 2 ;;
        --auth-secret) AUTH_SECRET="$2"; shift 2 ;;
        --tenant-id) CS_TENANT_ID="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; print_usage ;;
    esac
done


# Validate mandatory parameters
if [ -z "$PROJECT_ID" ] || [ -z "$AUTH_KEY" ] || [ -z "$AUTH_SECRET" ] || [ -z "$CS_TENANT_ID" ]; then
#    echo "$PROJECT_ID $AUTH_KEY $AUTH_SECRET $CS_TENANT_ID"
    echo "Error: Project id, auth key, secret and tenant id are mandatory."
    print_usage
fi

# Set default values if not provided
ROLE_NAME="${ROLE_NAME:-$DEFAULT_ROLE_NAME}"
SA_NAME="${SA_NAME:-$DEFAULT_SA_NAME}"
SA_DISPLAY_NAME="${SA_DISPLAY_NAME:-$DEFAULT_SA_DISPLAY_NAME}"
POST_URL="${POST_URL:-$DEFAULT_POST_URL}"

# Validate PROJECT_ID
if ! [[ "$PROJECT_ID" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    echo -e "${RED}Error: Invalid PROJECT_ID. It must start with a letter and can only contain alphanumeric characters, hyphens, or underscores.${RESET}"
    exit 1
fi

# Validate POST_URL
if ! [[ "$POST_URL" =~ ^https?:// ]]; then
    echo -e "${RED}Error: Invalid POST_URL. It must start with http:// or https://.${RESET}"
    exit 1
fi

# Validate ROLE_NAME
if [ ${#ROLE_NAME} -gt 64 ]; then
    echo -e "${RED}Error: ROLE_NAME must not exceed 64 characters.${RESET}"
    exit 1
fi

# Validate SA_NAME
if [ ${#SA_NAME} -gt 30 ]; then
    echo -e "${RED}Error: SA_NAME must not exceed 30 characters.${RESET}"
    exit 1
fi

# Validate SA_DISPLAY_NAME
if [ ${#SA_DISPLAY_NAME} -gt 100 ]; then
    echo -e "${RED}Error: SA_DISPLAY_NAME must not exceed 100 characters.${RESET}"
    exit 1
fi

# Validate ILLUMIO_SA_EMAIL
if ! [[ "$ILLUMIO_SA_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9_-]+\.iam\.gserviceaccount\.com$ ]]; then
    echo -e "${RED}Error: Invalid ILLUMIO_SA_EMAIL. It must be a valid email address.${RESET}"
    exit 1
fi

# Validate PROJECT_ID
if ! [[ "$PROJECT_ID" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    echo -e "${RED}Error: Invalid PROJECT_ID '$PROJECT_ID'. It must start with a letter and can only contain alphanumeric characters, hyphens, or underscores.${RESET}"
    exit 1
fi

# Determine resource type based on folder ID or organization ID presence
if [ -n "$FOLDER_ID" ] && [ -n "$ORGANIZATION_ID" ]; then
    RESOURCE_TYPE="$RESOURCE_TYPE_FOLDER"
    RESOURCE_ID="$FOLDER_ID"
    echo "Operating at folder level: $FOLDER_ID"

    # Validate folder ID format (typically numeric)
    if ! [[ "$FOLDER_ID" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid FOLDER_ID. It must be numeric.${RESET}"
        exit 1
    fi

    # Validate organization ID format (typically numeric)
    # This is required for folder onboarding to create custom IAM role
    if ! [[ "$ORGANIZATION_ID" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid ORGANIZATION_ID. It must be numeric. Organization id is required to create custom IAM role for folder onboarding${RESET}"
        exit 1
    fi

elif [ -n "$ORGANIZATION_ID" ]; then
    RESOURCE_TYPE="$RESOURCE_TYPE_ORGANIZATION"
    RESOURCE_ID="$ORGANIZATION_ID"
    echo "Operating at organization level: $ORGANIZATION_ID"

    # Validate organization ID format (typically numeric)
    if ! [[ "$ORGANIZATION_ID" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid ORGANIZATION_ID. It must be numeric.${RESET}"
        exit 1
    fi
else
    RESOURCE_TYPE="$RESOURCE_TYPE_PROJECT"
    RESOURCE_ID="$PROJECT_ID"
    echo "Operating at project level: $PROJECT_ID"
fi


# READ_WRITE_MODE
if $READ_WRITE_MODE; then
    echo "Read-write mode enabled."
else
    echo "Read-only mode."
fi

# Function to set the active project
set_project() {
    local project_id=$1
    echo "Setting active project to $project_id..."
    gcloud config set project "$project_id"
    echo -e "${GREEN}DONE${RESET}"
}

# Function to create service account
create_service_account() {
    local project_id=$1
    local sa_name=$2
    local sa_display_name=$3

    echo "Creating service account..."
    gcloud iam service-accounts create "$sa_name" \
        --display-name="$sa_display_name" \
        --project="$project_id" \
        --quiet
    #creating service account email using the service account name and project id
    local sa_email="${sa_name}@${project_id}.iam.gserviceaccount.com"
    echo "$sa_email"
}

# Function to check if service account is available with exponential backoff
check_service_account_availability() {
    local sa_email=$1
    local project_id=$2
    local delay=10
    local max_delay=300 # 5 minutes total
    local total_wait=0
    echo "Checking if service account $sa_email is available..."
    while [ $total_wait -lt $max_delay ]; do
        if gcloud iam service-accounts describe "$sa_email" --project="$project_id" --quiet > /dev/null 2>&1; then
            echo -e "${GREEN}Service account $sa_email is available.${RESET}"
            return 0
        else
            echo "Waiting for service account $sa_email to be available... Retrying in $delay seconds."
            sleep $delay
            total_wait=$((total_wait + delay))
            delay=$((delay * 2))
            if [ $delay -gt 60 ]; then
                delay=60
            fi
        fi
    done
    echo -e "${RED}Error: Service account $sa_email not available after 5 minutes.${RESET}"
    return 1
}

# Function to create IAM role
create_iam_role() {
    local resource_type=$1
    local resource_id=$2
    local role_name=$3
    local permissions=$4
    local organization_id=$5

    echo "Creating custom IAM role..."
    if [ "$resource_type" == "$RESOURCE_TYPE_PROJECT" ]; then
        gcloud iam roles create "$role_name" \
            --project="$resource_id" \
            --title="$role_name" \
            --description="Custom role for listing and getting storage and VPCs" \
            --permissions="$permissions" \
            --stage="GA" \
            --quiet > /dev/null
    elif [ "$resource_type" == "$RESOURCE_TYPE_ORGANIZATION" ]; then
         gcloud iam roles create "$role_name" \
             --organization="$resource_id" \
             --title="$role_name" \
             --description="Custom role for organization-level permissions" \
             --permissions="$permissions" \
             --stage="GA" \
             --quiet > /dev/null
    elif [ "$resource_type" == "$RESOURCE_TYPE_FOLDER" ]; then
#      iam role could only be created at project/organization level, for folder onboarding creating it at organization level
       gcloud iam roles create "$role_name" \
           --organization="$organization_id" \
           --title="$role_name" \
           --description="Custom role for folder-level permissions" \
           --permissions="$permissions" \
           --stage="GA" \
           --quiet > /dev/null
    fi
    add_resource "roles" "$role_name"
    echo -e "${GREEN}DONE${RESET}"
}

# Function to bind IAM role to service account
bind_role_to_service_account() {
    local resource_type=$1
    local resource_id=$2
    local sa_email=$3
    local role_name=$4
    local organization_id=$5

    echo "Binding custom IAM role to service account..."
    if [ "$resource_type" == "$RESOURCE_TYPE_PROJECT" ]; then
        gcloud projects add-iam-policy-binding "$resource_id" \
            --member="serviceAccount:$sa_email" \
            --role="projects/$resource_id/roles/$role_name" \
            --condition=None \
            --quiet > /dev/null
    elif [ "$resource_type" == "$RESOURCE_TYPE_ORGANIZATION" ]; then
         gcloud organizations add-iam-policy-binding "$resource_id" \
             --member="serviceAccount:$sa_email" \
             --role="organizations/$resource_id/roles/$role_name" \
             --condition=None \
             --quiet > /dev/null
    elif [ "$resource_type" == "$RESOURCE_TYPE_FOLDER" ]; then
         gcloud resource-manager folders add-iam-policy-binding "$resource_id" \
             --member="serviceAccount:$sa_email" \
             --role="organizations/$organization_id/roles/$role_name" \
             --condition=None \
             --quiet > /dev/null
    fi
    echo -e "${GREEN}DONE${RESET}"
}

# Function to assign predefined role to service account
assign_predefined_role() {
    local resource_type=$1
    local resource_id=$2
    local sa_email=$3
    local role=$4

    echo "Assigning predefined role $role to service account..."
    if [ "$resource_type" == "$RESOURCE_TYPE_PROJECT" ]; then
        gcloud projects add-iam-policy-binding "$resource_id" \
            --member="serviceAccount:$sa_email" \
            --role="$role" \
            --condition=None \
            --quiet > /dev/null
    elif  [ "$resource_type" == "$RESOURCE_TYPE_ORGANIZATION" ]; then
        gcloud organizations add-iam-policy-binding "$resource_id" \
                --member="serviceAccount:$sa_email" \
                --role="$role"\
                --condition=None \
                --quiet > /dev/null
    elif [ "$resource_type" == "$RESOURCE_TYPE_FOLDER" ]; then
        gcloud resource-manager folders add-iam-policy-binding "$resource_id" \
            --member="serviceAccount:$sa_email" \
            --role="$role" \
            --condition=None \
            --quiet > /dev/null
    fi
    echo -e "${GREEN}DONE${RESET}"
}

# Function to enable impersonation permissions
enable_impersonation_permissions() {
    local sa_email=$1
    local project_id=$2
    local illumio_sa_email=$3

    echo "Configuring impersonation permissions..."
    gcloud iam service-accounts add-iam-policy-binding "$sa_email" \
        --member="serviceAccount:$illumio_sa_email" \
        --role="roles/iam.serviceAccountTokenCreator" \
        --project="$project_id" \
        --condition=None \
        --quiet > /dev/null
    echo -e "${GREEN}DONE${RESET}"
}

send_data_to_endpoint() {
    local sa_email=$1
    local resource_id=$2
    local project_id=$3
    local post_url=$4
    local tenant_id=$5
    local auth_key=$6  # Basic Authentication key
    local auth_secret=$7  # Basic Authentication secret
    local event=$8
    local resource_type=$9

    if [[ "$post_url" !=  *"proxy"* ]] || [[ "$post_url" == *"sunnyvale"* ]]; then
        post_url="$post_url/api/v1/integrations/cloud_credentials"
    fi

    # Determine onboarding_type based on resource_type
    local integration_type=""
    if [ "$resource_type" == "project" ]; then
        integration_type="GcpProject"
    elif [ "$resource_type" == "folder" ]; then
        integration_type="GcpFolder"
    elif [ "$resource_type" == "organization" ]; then
        integration_type="GcpOrganization"
    else
        echo "Error: Invalid resource_type provided."
        exit 1
    fi

    echo "Sending resource ID, service account email, and project ID to $post_url"

    # Perform the HTTP POST request with Basic Authentication and custom headers
    response=$(curl -s -w "\n%{http_code}" -X POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Basic $(echo -n "$auth_key:$auth_secret" | base64 | tr -d '\n')" \
         -H "X-Tenant-Id: $tenant_id" \
         -d "{\"sa_email\":\"$sa_email\",\"gcp_resource_id\":\"$resource_id\",\"project_csp_id\":\"$project_id\",\"type\":\"$event\",\"integration_type\":\"$integration_type\"}" \
         "$post_url")

    # Extract the response body and status code
    body=$(echo "$response" | sed '$d')  # Remove last line (status code)
    status_code=$(echo "$response" | tail -n1)  # Extract last line (status code)

    # Check the HTTP status code
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        echo "POST request successful. Response:"
        echo "$body"
    else
        echo "Error: POST request failed with status code $status_code. Response:"
        echo "$body"
        exit 1  # Trigger cleanup via ERR trap if there's an error.
    fi
}

# Function to check if gcloud CLI is available
check_gcloud_availability() {
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Error: gcloud CLI is not available. Please install and configure it before running this script.${RESET}"
        exit 1
    fi
    echo "gcloud CLI is available. Proceeding with the script."
}

# Function to enable specific APIs for a project
enable_apis_for_project() {
    local project_id=$1
    echo "Enabling APIs (iamcredentials.googleapis.com, cloudresourcemanager.googleapis.com) for project $project_id..."
    if ! gcloud services enable iamcredentials.googleapis.com cloudresourcemanager.googleapis.com --project="$project_id" --quiet; then
        echo -e "${RED}Failed to enable required APIs for project $project_id.${RESET}"
        exit 1
    fi
    echo -e "${GREEN}DONE${RESET}"
}

# Main execution sequence
main() {
    check_gcloud_availability
    if [ "$RESOURCE_TYPE" == "$RESOURCE_TYPE_PROJECT" ]; then
        set_project "$PROJECT_ID"
    fi
    # TODO: Check user permissions before proceeding

    SA_EMAIL=$(create_service_account "$PROJECT_ID" "$SA_NAME" "$SA_DISPLAY_NAME" | tail -n 1)
    # doing add_resource here for service account because we are using a pipe (| tail -n 1) when calling the function, which creates a subshell.
    # Variables modified in subshells do not propagate back to the parent shell, hence the added service account was not visible in cleanup function
    add_resource "service_accounts" "$SA_EMAIL"
    # Check if service account is available before proceeding
    if ! check_service_account_availability "$SA_EMAIL" "$PROJECT_ID"; then
        exit 1
    fi

    # Prompt user for consent to enable APIs for Illumio-supported resources
    echo "Do you allow Illumio to enable APIs for supported resources at the time of ingestion? (y/N)"
    read -r consent
    if [[ "$consent" == "y" || "$consent" == "Y" ]]; then
        echo "User consented to enable APIs for Illumio-supported resources."
        create_iam_role "$RESOURCE_TYPE" "$RESOURCE_ID" "$DEFAULT_API_ENABLE_ROLE_NAME" "$API_ENABLE_PERMISSION" "$ORGANIZATION_ID"
        bind_role_to_service_account "$RESOURCE_TYPE" "$RESOURCE_ID" "$SA_EMAIL" "$DEFAULT_API_ENABLE_ROLE_NAME" "$ORGANIZATION_ID"
    else
        echo "User did not consent to enable APIs for Illumio-supported resources."
    fi

    # Convert the comma-separated list into an array and loop through it
    IFS=',' read -ra ROLES_ARRAY <<< "$PREDEFINED_ROLES"
    for role in "${ROLES_ARRAY[@]}"; do
        assign_predefined_role "$RESOURCE_TYPE" "$RESOURCE_ID" "$SA_EMAIL" "$role"
    done
    enable_impersonation_permissions "$SA_EMAIL" "$PROJECT_ID" "$ILLUMIO_SA_EMAIL"

    # required to list projects under the organization or folder
    if [ "$RESOURCE_TYPE" == "$RESOURCE_TYPE_ORGANIZATION" ] || [ "$RESOURCE_TYPE" == "$RESOURCE_TYPE_FOLDER" ]; then
      assign_predefined_role "$RESOURCE_TYPE" "$RESOURCE_ID" "$SA_EMAIL" "roles/browser"
    fi

    # Check if READ_WRITE_MODE is true to create and bind IAM role with WRITE_PERMISSIONS
    if $READ_WRITE_MODE; then
        echo "Read-write mode is enabled. Creating IAM role with write permissions..."
        create_iam_role "$RESOURCE_TYPE" "$RESOURCE_ID" "$DEFAULT_WRITE_ROLE_NAME" "$WRITE_PERMISSIONS" "$ORGANIZATION_ID"
        bind_role_to_service_account "$RESOURCE_TYPE" "$RESOURCE_ID" "$SA_EMAIL" "$DEFAULT_WRITE_ROLE_NAME" "$ORGANIZATION_ID"
    fi

    # Enable APIs for the project to allow impersonation and cloudresourcemanager to read child resources
    enable_apis_for_project "$PROJECT_ID"

    send_data_to_endpoint "$SA_EMAIL" "$RESOURCE_ID" "$PROJECT_ID" "$POST_URL" "$CS_TENANT_ID" "$AUTH_KEY" "$AUTH_SECRET" "GCPRole" "$RESOURCE_TYPE"
}

main
echo -e "${GREEN}Script executed successfully.${RESET}"