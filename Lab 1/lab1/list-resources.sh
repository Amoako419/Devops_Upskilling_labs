#!/bin/bash

# list-resources.sh
# Script to list all S3 buckets in the AWS account with their regions

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

print_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

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

# Function to get bucket region with special handling for us-east-1
get_bucket_region() {
    local bucket_name=$1
    local region
    
    # Get the bucket location
    region=$(aws s3api get-bucket-location --bucket "$bucket_name" --query 'LocationConstraint' --output text 2>/dev/null)
    
    # Handle the special case where us-east-1 returns "None"
    if [ "$region" = "None" ] || [ "$region" = "null" ] || [ -z "$region" ]; then
        echo "us-east-1"
    else
        echo "$region"
    fi
}

# Function to format region name with description
format_region() {
    local region=$1
    case $region in
        "us-east-1")
            echo "$region (N. Virginia)"
            ;;
        "us-east-2")
            echo "$region (Ohio)"
            ;;
        "us-west-1")
            echo "$region (N. California)"
            ;;
        "us-west-2")
            echo "$region (Oregon)"
            ;;
        "eu-west-1")
            echo "$region (Ireland)"
            ;;
        "eu-west-2")
            echo "$region (London)"
            ;;
        "eu-west-3")
            echo "$region (Paris)"
            ;;
        "eu-central-1")
            echo "$region (Frankfurt)"
            ;;
        "eu-north-1")
            echo "$region (Stockholm)"
            ;;
        "ap-southeast-1")
            echo "$region (Singapore)"
            ;;
        "ap-southeast-2")
            echo "$region (Sydney)"
            ;;
        "ap-northeast-1")
            echo "$region (Tokyo)"
            ;;
        "ap-northeast-2")
            echo "$region (Seoul)"
            ;;
        "ap-south-1")
            echo "$region (Mumbai)"
            ;;
        "ca-central-1")
            echo "$region (Canada Central)"
            ;;
        "sa-east-1")
            echo "$region (São Paulo)"
            ;;
        *)
            echo "$region"
            ;;
    esac
}

# Function to get bucket creation date
get_bucket_creation_date() {
    local bucket_name=$1
    aws s3api list-buckets --query "Buckets[?Name=='$bucket_name'].CreationDate" --output text 2>/dev/null | head -1
}

# Function to get bucket versioning status
get_bucket_versioning() {
    local bucket_name=$1
    local region=$2
    
    local versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --region "$region" --query 'Status' --output text 2>/dev/null)
    
    if [ "$versioning_status" = "Enabled" ]; then
        echo "Enabled"
    elif [ "$versioning_status" = "Suspended" ]; then
        echo "Suspended"
    else
        echo "Disabled"
    fi
}

# Function to count objects in bucket
count_bucket_objects() {
    local bucket_name=$1
    local region=$2
    
    # Use aws s3 ls to count objects (faster than s3api list-objects-v2 for large buckets)
    local object_count=$(aws s3 ls "s3://$bucket_name" --recursive --region "$region" 2>/dev/null | wc -l)
    echo "$object_count"
}

# Function to list S3 buckets with detailed information
list_s3_buckets() {
    print_status "Retrieving list of S3 buckets..."
    
    # Get list of all buckets
    local buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)
    
    if [ -z "$buckets" ]; then
        print_warning "No S3 buckets found in your account."
        return 0
    fi
    
    local bucket_count=$(echo "$buckets" | wc -w)
    print_success "Found $bucket_count S3 bucket(s)"
    
    echo
    print_header "═══════════════════════════════════════════════════════════════════════════════"
    print_header "                              S3 BUCKET INVENTORY                              "
    print_header "═══════════════════════════════════════════════════════════════════════════════"
    echo
    
    # Table header
    printf "%-40s %-25s %-12s %-10s %s\n" "BUCKET NAME" "REGION" "VERSIONING" "OBJECTS" "CREATED"
    printf "%-40s %-25s %-12s %-10s %s\n" "$(printf '%*s' 40 '' | tr ' ' '-')" "$(printf '%*s' 25 '' | tr ' ' '-')" "$(printf '%*s' 12 '' | tr ' ' '-')" "$(printf '%*s' 10 '' | tr ' ' '-')" "$(printf '%*s' 19 '' | tr ' ' '-')"
    
    # Process each bucket
    local counter=1
    for bucket in $buckets; do
        print_status "Processing bucket $counter/$bucket_count: $bucket"
        
        # Get bucket region
        local region=$(get_bucket_region "$bucket")
        local formatted_region=$(format_region "$region")
        
        # Get bucket creation date
        local creation_date=$(get_bucket_creation_date "$bucket")
        local formatted_date=$(date -d "$creation_date" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$creation_date")
        
        # Get versioning status
        local versioning=$(get_bucket_versioning "$bucket" "$region")
        
        # Count objects (with timeout to avoid hanging on large buckets)
        local object_count
        if timeout 10s bash -c "count_bucket_objects '$bucket' '$region'" 2>/dev/null; then
            object_count=$(count_bucket_objects "$bucket" "$region")
        else
            object_count="N/A"
        fi
        
        # Display bucket information
        printf "%-40s %-25s %-12s %-10s %s\n" \
            "$bucket" \
            "$formatted_region" \
            "$versioning" \
            "$object_count" \
            "$formatted_date"
        
        ((counter++))
    done
    
    echo
    print_header "═══════════════════════════════════════════════════════════════════════════════"
    
    # Summary by region
    echo
    print_header "SUMMARY BY REGION:"
    echo
    
    # Create associative array to count buckets per region
    declare -A region_count
    
    for bucket in $buckets; do
        local region=$(get_bucket_region "$bucket")
        local formatted_region=$(format_region "$region")
        if [[ -n "${region_count[$formatted_region]}" ]]; then
            ((region_count[$formatted_region]++))
        else
            region_count[$formatted_region]=1
        fi
    done
    
    # Display region summary
    for region in "${!region_count[@]}"; do
        printf "  %-30s : %d bucket(s)\n" "$region" "${region_count[$region]}"
    done
    
    echo
    print_success "Total buckets in account: $bucket_count"
}

# Function to export bucket list to CSV
export_to_csv() {
    local csv_file="s3-bucket-inventory-$(date +%Y%m%d-%H%M%S).csv"
    
    print_status "Exporting bucket inventory to CSV: $csv_file"
    
    # CSV header
    echo "Bucket Name,Region,Region Description,Versioning Status,Object Count,Creation Date" > "$csv_file"
    
    # Get list of all buckets
    local buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)
    
    for bucket in $buckets; do
        local region=$(get_bucket_region "$bucket")
        local formatted_region=$(format_region "$region")
        local creation_date=$(get_bucket_creation_date "$bucket")
        local versioning=$(get_bucket_versioning "$bucket" "$region")
        local object_count=$(count_bucket_objects "$bucket" "$region")
        
        echo "$bucket,$region,$formatted_region,$versioning,$object_count,$creation_date" >> "$csv_file"
    done
    
    print_success "CSV export completed: $csv_file"
}

# Function to show script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "List all S3 buckets in your AWS account with their regions and details."
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --csv      Export results to CSV file"
    echo "  -v, --verbose  Show detailed processing information"
    echo
    echo "Features:"
    echo "  - Lists all S3 buckets with regions"
    echo "  - Handles us-east-1 special case (shows 'us-east-1' instead of 'None')"
    echo "  - Shows versioning status and object count"
    echo "  - Displays creation date and regional summary"
    echo "  - Optional CSV export for further analysis"
    echo
    echo "Requirements:"
    echo "  - AWS CLI installed and configured"
    echo "  - Appropriate IAM permissions for S3 read operations"
    echo
}

# Main execution function
main() {
    local export_csv=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--csv)
                export_csv=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Set verbose mode
    if [ "$verbose" = true ]; then
        set -x
    fi
    
    print_header "S3 Resource Inventory Script"
    print_status "Started at: $(date)"
    echo
    
    # Check prerequisites
    check_aws_cli
    
    # Get current AWS account info
    local account_id=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
    local aws_region=$(aws configure get region 2>/dev/null || echo "Not set")
    
    echo
    print_status "AWS Account ID: $account_id"
    print_status "Default AWS Region: $aws_region"
    echo
    
    # List S3 buckets
    list_s3_buckets
    
    # Export to CSV if requested
    if [ "$export_csv" = true ]; then
        echo
        export_to_csv
    fi
    
    echo
    print_success "S3 resource inventory completed successfully!"
    print_status "Completed at: $(date)"
}

# Run main function with all arguments
main "$@"