#!/bin/bash
# Terraform Destroy Script for Stack1 and Stack2
# This script destroys all resources created by both stacks in the correct order

set -e  # Exit on error

echo "=================================================="
echo "Terraform Destroy Script for Stack1 and Stack2"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
STACK1_DIR="$SCRIPT_DIR/stack1"
STACK2_DIR="$SCRIPT_DIR/stack2"

# Function to destroy a stack
destroy_stack() {
    local stack_name=$1
    local stack_dir=$2

    echo -e "${YELLOW}Destroying $stack_name...${NC}"

    if [ ! -d "$stack_dir" ]; then
        echo -e "${RED}Error: Directory $stack_dir not found${NC}"
        return 1
    fi

    cd "$stack_dir"

    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        echo -e "${YELLOW}Warning: No terraform state found for $stack_name. Skipping...${NC}"
        return 0
    fi

    # Run terraform destroy
    echo -e "${GREEN}Running terraform destroy for $stack_name...${NC}"
    terraform destroy -auto-approve

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully destroyed $stack_name${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to destroy $stack_name${NC}"
        return 1
    fi
}

# Confirmation prompt
echo -e "${RED}WARNING: This will destroy ALL resources in both Stack1 and Stack2!${NC}"
echo "This includes:"
echo "  - Bedrock Knowledge Base and Data Sources"
echo "  - Aurora Serverless Database Cluster"
echo "  - S3 Buckets (and all contents)"
echo "  - VPC and all networking resources"
echo "  - IAM Roles and Policies"
echo "  - Secrets Manager secrets"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Destroy operation cancelled."
    exit 0
fi

echo ""
echo "Starting destroy process..."
echo ""

# Step 1: Destroy Stack2 (Bedrock KB - dependent on Stack1)
echo "=================================================="
echo "Step 1: Destroying Stack2 (Bedrock Knowledge Base)"
echo "=================================================="
destroy_stack "Stack2" "$STACK2_DIR"

# Step 2: Destroy Stack1 (Infrastructure)
echo "=================================================="
echo "Step 2: Destroying Stack1 (Infrastructure)"
echo "=================================================="
destroy_stack "Stack1" "$STACK1_DIR"

# Return to original directory
cd "$SCRIPT_DIR"

echo ""
echo "=================================================="
echo -e "${GREEN}✓ All resources have been destroyed successfully!${NC}"
echo "=================================================="
echo ""
echo "Cleanup complete. All infrastructure has been removed."
