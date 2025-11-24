# Terraform Destroy Configuration
# This file ensures all resources from stack1 and stack2 are properly destroyed
#
# Usage:
#   1. Navigate to stack2 directory and run: terraform destroy
#   2. Navigate to stack1 directory and run: terraform destroy
#
# Or use the provided destroy script (see destroy.sh)

# Note: Resources must be destroyed in the correct order due to dependencies:
# 1. Stack2 (Bedrock KB) must be destroyed first as it depends on Stack1 resources
# 2. Stack1 (VPC, Aurora, S3) can be destroyed after Stack2

# Stack2 Resources (to be destroyed first):
# - AWS Bedrock Agent Knowledge Base Data Source
# - AWS Bedrock Agent Knowledge Base
# - IAM Role Policy Attachments (Bedrock KB)
# - IAM Policies (RDS Data API, Bedrock KB RDS Access)
# - IAM Role (Bedrock KB)
# - Time Sleep Resource

# Stack1 Resources (to be destroyed second):
# - S3 Bucket (with force_destroy enabled)
# - Aurora RDS Cluster Instance
# - Aurora RDS Cluster
# - AWS Secrets Manager Secret Version
# - AWS Secrets Manager Secret
# - Random Password
# - Security Group (Aurora)
# - DB Subnet Group
# - VPC Module Resources (NAT Gateway, Subnets, Internet Gateway, Route Tables, VPC)

terraform {
  required_version = ">= 1.0"
}

# This file serves as documentation for the destroy process.
# The actual destruction should be performed by running 'terraform destroy'
# in each stack directory in the correct order.
