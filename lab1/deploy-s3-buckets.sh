#!/bin/bash

# deploy-s3-buckets.sh
# Script to deploy S3 buckets to multiple AWS regions with versioning enabled

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Generate timestamp for unique bucket names
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BASE_BUCKET_NAME="devops-upskilling-bucket"

# Define regions
REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    print_status "Checking AWS CLI installation and configuration..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or credentials are invalid."
        print_error "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    print_success "AWS CLI is properly configured"
}

# Function to create S3 bucket
create_bucket() {
    local region=$1
    local bucket_name="${BASE_BUCKET_NAME}-${region}-${TIMESTAMP}"
    
    print_status "Creating S3 bucket: ${bucket_name} in region: ${region}"
    
    # Create bucket with region-specific handling
    if [ "$region" = "us-east-1" ]; then
        # us-east-1 doesn't require LocationConstraint
        aws s3api create-bucket \
            --bucket "$bucket_name" \
            --region "$region" \
            --output text
    else
        # Other regions require LocationConstraint
        aws s3api create-bucket \
            --bucket "$bucket_name" \
            --region "$region" \
            --create-bucket-configuration LocationConstraint="$region" \
            --output text
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Successfully created bucket: ${bucket_name}"
        
        # Enable versioning on the bucket
        enable_versioning "$bucket_name" "$region"
        
        # Add tags to the bucket
        tag_bucket "$bucket_name" "$region"
        
        echo "$bucket_name" >> created_buckets.log
    else
        print_error "Failed to create bucket: ${bucket_name}"
        return 1
    fi
}

# Function to enable versioning on S3 bucket
enable_versioning() {
    local bucket_name=$1
    local region=$2
    
    print_status "Enabling versioning on bucket: ${bucket_name}"
    
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --region "$region" \
        --versioning-configuration Status=Enabled \
        --output text
    
    if [ $? -eq 0 ]; then
        print_success "Versioning enabled on bucket: ${bucket_name}"
    else
        print_error "Failed to enable versioning on bucket: ${bucket_name}"
    fi
}

# Function to add tags to the bucket
tag_bucket() {
    local bucket_name=$1
    local region=$2
    
    print_status "Adding tags to bucket: ${bucket_name}"
    
    aws s3api put-bucket-tagging \
        --bucket "$bucket_name" \
        --region "$region" \
        --tagging 'TagSet=[
            {
                "Key": "Project",
                "Value": "DevOps-Upskilling"
            },
            {
                "Key": "Environment",
                "Value": "Development"
            },
            {
                "Key": "CreatedBy",
                "Value": "deploy-s3-buckets-script"
            },
            {
                "Key": "CreatedDate",
                "Value": "'$(date +%Y-%m-%d)'"
            },
            {
                "Key": "Region",
                "Value": "'$region'"
            }
        ]' \
        --output text
    
    if [ $? -eq 0 ]; then
        print_success "Tags added to bucket: ${bucket_name}"
    else
        print_warning "Failed to add tags to bucket: ${bucket_name}"
    fi
}

# Function to verify bucket creation and configuration
verify_bucket() {
    local bucket_name=$1
    local region=$2
    
    print_status "Verifying bucket configuration: ${bucket_name}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$bucket_name" --region "$region" 2>/dev/null; then
        print_success "Bucket exists: ${bucket_name}"
        
        # Check versioning status
        local versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --region "$region" --query 'Status' --output text 2>/dev/null)
        if [ "$versioning_status" = "Enabled" ]; then
            print_success "Versioning is enabled on: ${bucket_name}"
        else
            print_warning "Versioning status unclear for: ${bucket_name}"
        fi
    else
        print_error "Bucket verification failed: ${bucket_name}"
    fi
}

# Function to clean up on failure (optional)
cleanup_on_failure() {
    if [ -f "created_buckets.log" ]; then
        print_warning "Cleaning up buckets created during this run..."
        while IFS= read -r bucket_name; do
            local region=$(echo "$bucket_name" | cut -d'-' -f4)
            print_status "Deleting bucket: ${bucket_name}"
            aws s3 rb "s3://${bucket_name}" --force --region "$region" 2>/dev/null || true
        done < created_buckets.log
        rm -f created_buckets.log
    fi
}

# Main execution
main() {
    print_status "Starting S3 bucket deployment script"
    print_status "Timestamp: ${TIMESTAMP}"
    print_status "Base bucket name: ${BASE_BUCKET_NAME}"
    
    # Initialize log file
    > created_buckets.log
    
    # Check prerequisites
    check_aws_cli
    
    # Set up error handling
    trap cleanup_on_failure ERR
    
    # Create buckets in all regions
    for region in "${REGIONS[@]}"; do
        echo
        print_status "Processing region: ${region}"
        create_bucket "$region"
        
        # Add a small delay between bucket creations
        sleep 2
    done
    
    echo
    print_status "Verifying all created buckets..."
    
    # Verify all created buckets
    if [ -f "created_buckets.log" ]; then
        while IFS= read -r bucket_name; do
            local region=$(echo "$bucket_name" | cut -d'-' -f4)
            verify_bucket "$bucket_name" "$region"
        done < created_buckets.log
    fi
    
    echo
    print_success "S3 bucket deployment completed successfully!"
    print_status "Created buckets:"
    
    if [ -f "created_buckets.log" ]; then
        while IFS= read -r bucket_name; do
            echo "  - $bucket_name"
        done < created_buckets.log
    fi
    
    echo
    print_status "Log file: created_buckets.log contains the list of created buckets"
}

# Script usage information
usage() {
    echo "Usage: $0"
    echo
    echo "This script creates S3 buckets in multiple AWS regions:"
    echo "  - us-east-1 (N. Virginia)"
    echo "  - eu-west-1 (Ireland)"
    echo "  - ap-southeast-1 (Singapore)"
    echo
    echo "Requirements:"
    echo "  - AWS CLI installed and configured"
    echo "  - Appropriate IAM permissions for S3 operations"
    echo
    echo "Features:"
    echo "  - Unique bucket names with timestamp"
    echo "  - Versioning enabled on all buckets"
    echo "  - Proper handling of us-east-1 region constraints"
    echo "  - Comprehensive error handling and logging"
    echo "  - Bucket verification and tagging"
    echo
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main

print_status "Script execution completed."