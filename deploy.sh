#!/bin/bash
# GCP Landing Zone Deployment Script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud SDK is not installed. Please install gcloud"
        exit 1
    fi
    
    # Check if logged in to gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        print_error "Not authenticated with gcloud. Please run 'gcloud auth login'"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

enable_apis() {
    print_info "Enabling required APIs..."
    
    local apis=(
        "cloudresourcemanager.googleapis.com"
        "cloudbilling.googleapis.com"
        "iam.googleapis.com"
        "serviceusage.googleapis.com"
        "compute.googleapis.com"
        "logging.googleapis.com"
        "monitoring.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        print_info "Enabling $api..."
        gcloud services enable "$api" || print_warn "Failed to enable $api (may already be enabled)"
    done
}

validate_tfvars() {
    print_info "Validating terraform.tfvars..."
    
    # Check for required variables
    local required_vars=(
        "org_domain"
        "billing_account"
        "admin_group_email"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}" terraform.tfvars; then
            print_error "Required variable '$var' not found in terraform.tfvars"
            exit 1
        fi
    done
    
    print_info "terraform.tfvars validation passed"
}

init_terraform() {
    print_info "Initializing Terraform..."
    
    # Check if backend is configured
    if grep -q "backend \"gcs\"" main.tf; then
        print_info "GCS backend detected. Ensure the bucket exists before proceeding."
        read -p "Has the GCS backend bucket been created? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Please create the GCS bucket for Terraform state first"
            exit 1
        fi
    fi
    
    terraform init
}

plan_deployment() {
    print_info "Running Terraform plan..."
    
    # Create plan output directory
    mkdir -p plans
    
    # Generate timestamp for plan file
    timestamp=$(date +%Y%m%d_%H%M%S)
    plan_file="plans/tfplan_${timestamp}"
    
    # Run terraform plan
    if terraform plan -out="$plan_file"; then
        print_info "Plan saved to $plan_file"
        return 0
    else
        print_error "Terraform plan failed"
        return 1
    fi
}

apply_deployment() {
    local plan_file=$1
    
    print_info "Applying Terraform plan..."
    print_warn "This will create resources in your GCP organization"
    
    read -p "Do you want to proceed with the deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    if terraform apply "$plan_file"; then
        print_info "Deployment completed successfully!"
        return 0
    else
        print_error "Deployment failed"
        return 1
    fi
}

post_deployment() {
    print_info "Post-deployment tasks:"
    echo
    echo "1. Configure Dedicated Interconnects in the Console"
    echo "2. Set up Google Cloud Directory Sync (GCDS)"
    echo "3. Configure Azure AD SAML federation"
    echo "4. Set up Splunk integration for log consumption"
    echo "5. Review and adjust firewall policies"
    echo
    print_info "See SETUP_GUIDE.md for detailed instructions"
}

# Main execution
main() {
    print_info "GCP Landing Zone Deployment Script"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Validate configuration
    validate_tfvars
    
    # Enable APIs
    print_info "Do you want to enable required APIs? (y/n)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        enable_apis
    fi
    
    # Initialize Terraform
    init_terraform
    
    # Plan deployment
    if plan_deployment; then
        # Find the latest plan file
        latest_plan=$(ls -t plans/tfplan_* 2>/dev/null | head -1)
        
        if [ -z "$latest_plan" ]; then
            print_error "No plan file found"
            exit 1
        fi
        
        print_info "Review the plan output above"
        echo
        
        # Apply deployment
        apply_deployment "$latest_plan"
        
        # Show post-deployment tasks
        post_deployment
    fi
}

# Run main function
main "$@"