#!/bin/bash

# Simplified AWS Security Audit Script
# Works on Windows with minimal dependencies

# Colors and symbols
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
WARNINGS=0
TOTAL=0

OUTPUT_FILE="audit-results.txt"

# Helper functions
pass_check() {
    echo -e "${GREEN}✓${NC} $1"
    echo "✓ $1" >> "$OUTPUT_FILE"
    ((PASSED++))
    ((TOTAL++))
}

fail_check() {
    echo -e "${RED}✗${NC} $1"
    echo "✗ $1" >> "$OUTPUT_FILE"
    ((FAILED++))
    ((TOTAL++))
}

warn_check() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "⚠ $1" >> "$OUTPUT_FILE"
    ((WARNINGS++))
    ((TOTAL++))
}

info_msg() {
    echo -e "${BLUE}ℹ${NC} $1"
    echo "ℹ $1" >> "$OUTPUT_FILE"
}

section_header() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
    echo "" >> "$OUTPUT_FILE"
    echo "--- $1 ---" >> "$OUTPUT_FILE"
}

# Initialize output file
echo "AWS Security Audit Report" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "==============================" >> "$OUTPUT_FILE"

echo -e "${BLUE}AWS Security Audit Tool${NC}"
echo -e "${BLUE}Generated: $(date)${NC}"
echo ""

# Check prerequisites
section_header "PREREQUISITE CHECKS"

if command -v aws >/dev/null 2>&1; then
    pass_check "AWS CLI is installed"
else
    fail_check "AWS CLI is not installed"
    exit 1
fi

if aws sts get-caller-identity >/dev/null 2>&1; then
    pass_check "AWS CLI is properly configured"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
    REGION=$(aws configure get region 2>/dev/null || echo "Not set")
    USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)
    
    info_msg "Account ID: $ACCOUNT_ID"
    info_msg "Default Region: $REGION"
    info_msg "User/Role: $USER_ARN"
else
    fail_check "AWS CLI is not configured or credentials are invalid"
    exit 1
fi

# S3 Security Audit
section_header "S3 BUCKET SECURITY AUDIT"

BUCKETS=$(aws s3 ls --output text 2>/dev/null | awk '{print $3}')

if [ -z "$BUCKETS" ]; then
    info_msg "No S3 buckets found in account"
else
    BUCKET_COUNT=$(echo "$BUCKETS" | wc -l)
    info_msg "Found $BUCKET_COUNT S3 bucket(s) to audit"
    
    for bucket in $BUCKETS; do
        # Check public access block
        PUBLIC_ACCESS=$(aws s3api get-public-access-block --bucket "$bucket" --output text 2>/dev/null || echo "NONE")
        if [ "$PUBLIC_ACCESS" = "NONE" ]; then
            fail_check "Bucket '$bucket': No public access block configured"
        else
            pass_check "Bucket '$bucket': Public access block configured"
        fi
        
        # Check encryption
        ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$bucket" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "None")
        if [ "$ENCRYPTION" = "None" ]; then
            fail_check "Bucket '$bucket': No default encryption configured"
        else
            pass_check "Bucket '$bucket': Default encryption enabled ($ENCRYPTION)"
        fi
        
        # Check versioning
        VERSIONING=$(aws s3api get-bucket-versioning --bucket "$bucket" --query 'Status' --output text 2>/dev/null || echo "Disabled")
        if [ "$VERSIONING" = "Enabled" ]; then
            pass_check "Bucket '$bucket': Versioning enabled"
        else
            warn_check "Bucket '$bucket': Versioning not enabled"
        fi
    done
fi

# IAM Security Audit
section_header "IAM SECURITY AUDIT"

# Check root MFA
ROOT_MFA=$(aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text 2>/dev/null || echo "0")
if [ "$ROOT_MFA" = "1" ]; then
    pass_check "Root account MFA is enabled"
else
    fail_check "Root account MFA is NOT enabled"
fi

# Check password policy
PASSWORD_POLICY=$(aws iam get-account-password-policy --output text 2>/dev/null || echo "NONE")
if [ "$PASSWORD_POLICY" = "NONE" ]; then
    fail_check "No password policy configured"
else
    pass_check "Password policy is configured"
fi

# Generate credential report (simplified)
info_msg "Attempting to generate IAM credential report..."
aws iam generate-credential-report >/dev/null 2>&1
sleep 2

CRED_REPORT=$(aws iam get-credential-report --query 'Content' --output text 2>/dev/null || echo "NONE")
if [ "$CRED_REPORT" != "NONE" ]; then
    pass_check "IAM credential report generated successfully"
else
    warn_check "Could not generate IAM credential report"
fi

# CloudTrail Audit
section_header "CLOUDTRAIL AUDIT"

TRAILS=$(aws cloudtrail describe-trails --query 'trailList[].Name' --output text 2>/dev/null || echo "")
if [ -z "$TRAILS" ]; then
    fail_check "No CloudTrail trails configured"
else
    TRAIL_COUNT=$(echo "$TRAILS" | wc -w)
    info_msg "Found $TRAIL_COUNT CloudTrail trail(s)"
    
    ACTIVE_TRAILS=0
    for trail in $TRAILS; do
        STATUS=$(aws cloudtrail get-trail-status --name "$trail" --query 'IsLogging' --output text 2>/dev/null || echo "false")
        if [ "$STATUS" = "True" ]; then
            pass_check "CloudTrail '$trail': Active and logging"
            ((ACTIVE_TRAILS++))
        else
            fail_check "CloudTrail '$trail': Not actively logging"
        fi
    done
    
    if [ "$ACTIVE_TRAILS" -gt 0 ]; then
        pass_check "CloudTrail is actively logging events"
    else
        fail_check "No active CloudTrail logging found"
    fi
fi

# VPC Flow Logs Audit
section_header "VPC FLOW LOGS AUDIT"

VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --output text 2>/dev/null || echo "")
if [ -z "$VPCS" ]; then
    info_msg "No VPCs found in current region"
else
    VPC_COUNT=$(echo "$VPCS" | wc -w)
    info_msg "Found $VPC_COUNT VPC(s) to audit"
    
    for vpc in $VPCS; do
        FLOW_LOGS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc" --query 'FlowLogs[?FlowLogStatus==`ACTIVE`]' --output text 2>/dev/null || echo "")
        if [ -n "$FLOW_LOGS" ]; then
            pass_check "VPC '$vpc': Flow logs enabled and active"
        else
            fail_check "VPC '$vpc': No active flow logs configured"
        fi
    done
fi

# Security Groups Audit
section_header "SECURITY GROUPS AUDIT"

# Check for SSH open to world
SSH_OPEN=$(aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?FromPort==`22` && IpRanges[?CidrIp==`0.0.0.0/0`]]]' --output text 2>/dev/null | wc -l)
if [ "$SSH_OPEN" -gt 0 ]; then
    fail_check "$SSH_OPEN security group(s) have SSH (port 22) open to 0.0.0.0/0"
else
    pass_check "No security groups have SSH open to the world"
fi

# Check for RDP open to world
RDP_OPEN=$(aws ec2 describe-security-groups --query 'SecurityGroups[?IpPermissions[?FromPort==`3389` && IpRanges[?CidrIp==`0.0.0.0/0`]]]' --output text 2>/dev/null | wc -l)
if [ "$RDP_OPEN" -gt 0 ]; then
    fail_check "$RDP_OPEN security group(s) have RDP (port 3389) open to 0.0.0.0/0"
else
    pass_check "No security groups have RDP open to the world"
fi

# EC2 Security Audit
section_header "EC2 INSTANCES SECURITY AUDIT"

INSTANCES=$(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`].InstanceId' --output text 2>/dev/null || echo "")
if [ -z "$INSTANCES" ]; then
    info_msg "No EC2 instances found in current region"
else
    INSTANCE_COUNT=$(echo "$INSTANCES" | wc -w)
    info_msg "Found $INSTANCE_COUNT EC2 instance(s) to audit"
    
    PUBLIC_INSTANCES=0
    for instance in $INSTANCES; do
        PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$instance" --query 'Reservations[].Instances[].PublicIpAddress' --output text 2>/dev/null || echo "None")
        if [ "$PUBLIC_IP" != "None" ] && [ -n "$PUBLIC_IP" ]; then
            warn_check "Instance '$instance': Has public IP address"
            ((PUBLIC_INSTANCES++))
        else
            pass_check "Instance '$instance': No public IP address"
        fi
    done
    
    if [ "$PUBLIC_INSTANCES" -eq 0 ]; then
        pass_check "No instances have public IP addresses"
    else
        warn_check "$PUBLIC_INSTANCES instance(s) have public IP addresses"
    fi
fi

# Generate Summary
section_header "SECURITY AUDIT SUMMARY"

PASS_RATE=0
if [ "$TOTAL" -gt 0 ]; then
    PASS_RATE=$((PASSED * 100 / TOTAL))
fi

echo "Total Security Checks: $TOTAL" | tee -a "$OUTPUT_FILE"
echo "✓ Passed: $PASSED" | tee -a "$OUTPUT_FILE"
echo "⚠ Warnings: $WARNINGS" | tee -a "$OUTPUT_FILE"
echo "✗ Failed: $FAILED" | tee -a "$OUTPUT_FILE"
echo "Pass Rate: $PASS_RATE%" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

TOTAL_ISSUES=$((FAILED + WARNINGS))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}Security Status: EXCELLENT${NC}" | tee -a "$OUTPUT_FILE"
    echo "No security issues found!" | tee -a "$OUTPUT_FILE"
elif [ "$TOTAL_ISSUES" -le 5 ]; then
    echo -e "${YELLOW}Security Status: GOOD${NC}" | tee -a "$OUTPUT_FILE"
    echo "Minor security improvements recommended." | tee -a "$OUTPUT_FILE"
elif [ "$TOTAL_ISSUES" -le 15 ]; then
    echo -e "${YELLOW}Security Status: MODERATE${NC}" | tee -a "$OUTPUT_FILE"
    echo "Several security issues need attention." | tee -a "$OUTPUT_FILE"
else
    echo -e "${RED}Security Status: POOR${NC}" | tee -a "$OUTPUT_FILE"
    echo "Critical security issues require immediate attention!" | tee -a "$OUTPUT_FILE"
fi

echo "" | tee -a "$OUTPUT_FILE"
echo "Recommendations:" | tee -a "$OUTPUT_FILE"
echo "1. Address all failed checks immediately" | tee -a "$OUTPUT_FILE"
echo "2. Review and resolve warning items" | tee -a "$OUTPUT_FILE"
echo "3. Implement regular security audits" | tee -a "$OUTPUT_FILE"
echo "4. Review AWS Security Best Practices" | tee -a "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}Audit completed successfully!${NC}"
echo -e "${BLUE}Full results saved to: $OUTPUT_FILE${NC}"