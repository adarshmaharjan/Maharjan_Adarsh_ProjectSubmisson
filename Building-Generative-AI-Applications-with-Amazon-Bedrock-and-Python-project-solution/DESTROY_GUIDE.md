# Terraform Destroy Guide

## Overview

This guide explains how to safely destroy all resources created by Stack1 and Stack2.

## Resources to be Destroyed

### Stack2 Resources (Bedrock Knowledge Base)

- AWS Bedrock Agent Knowledge Base
- AWS Bedrock Agent Data Source (S3)
- IAM Role for Bedrock KB
- IAM Policies (RDS Data API access, Bedrock KB RDS access)
- IAM Role Policy Attachments

### Stack1 Resources (Infrastructure)

- VPC and all networking components (subnets, route tables, NAT gateway, internet gateway)
- Aurora Serverless v2 PostgreSQL Cluster
- Aurora Cluster Instance
- RDS Security Group
- DB Subnet Group
- S3 Bucket for Knowledge Base documents
- AWS Secrets Manager Secret (database credentials)
- Random Password Resource

## Destroy Methods

### Method 1: Automated Script (Recommended)

Use the provided `destroy.sh` script that handles the correct order automatically:

```bash
./destroy.sh
```

The script will:

1. Prompt for confirmation
2. Destroy Stack2 first (Bedrock KB resources)
3. Destroy Stack1 second (infrastructure resources)
4. Provide status updates throughout the process

### Method 2: Manual Destruction

If you prefer to destroy resources manually:

```bash
# Step 1: Destroy Stack2 (must be done first)
cd stack2
terraform destroy

# Step 2: Destroy Stack1 (can be done after Stack2 is destroyed)
cd ../stack1
terraform destroy
```

## Important Notes

### Destroy Order

**CRITICAL:** Stack2 must be destroyed before Stack1 because:

- Stack2's Bedrock Knowledge Base depends on Stack1's Aurora database
- Stack2's Data Source references Stack1's S3 bucket
- Stack2's IAM policies reference Stack1's Aurora cluster ARN and Secrets Manager secret

### Data Loss Warning

⚠️ **WARNING:** Destroying these resources will result in:

- **Permanent deletion** of the Aurora database and all data
- **Permanent deletion** of the S3 bucket and all documents (force_destroy is enabled)
- **Permanent deletion** of the Bedrock Knowledge Base and its configuration
- **Permanent deletion** of database credentials from Secrets Manager

### Recovery

- The Aurora cluster is configured with `skip_final_snapshot = true`, meaning no final snapshot will be taken
- The S3 bucket has `force_destroy = true`, allowing deletion even with objects inside
- The Secrets Manager secret has `recovery_window_in_days = 0`, meaning immediate deletion

## Troubleshooting

### If Stack2 Destroy Fails

If you encounter errors destroying Stack2, check:

- That the Bedrock Knowledge Base isn't currently being synced
- IAM role deletion issues (ensure no other resources are using the role)

### If Stack1 Destroy Fails

Common issues:

- **VPC deletion**: Ensure all ENIs (Elastic Network Interfaces) are detached
- **Security Group**: May fail if still attached to running resources
- **S3 Bucket**: Should auto-delete with force_destroy, but verify no bucket policies are blocking deletion

### Manual Cleanup

If automated destroy fails, you can manually delete resources via AWS Console in this order:

1. Bedrock Knowledge Base Data Sources
2. Bedrock Knowledge Base
3. IAM Role Policy Attachments
4. IAM Policies
5. IAM Roles
6. Aurora Cluster Instance
7. Aurora Cluster
8. S3 Bucket (empty it first if force_destroy didn't work)
9. Secrets Manager Secret
10. Security Groups
11. DB Subnet Group
12. VPC components (NAT Gateway, Internet Gateway, Subnets, Route Tables, VPC)

## Verification

After destruction, verify in AWS Console:

```bash
# Check for remaining resources
aws rds describe-db-clusters --query 'DBClusters[?ClusterIdentifier==`my-aurora-serverless`]'
aws s3 ls | grep bedrock-kb
aws bedrock-agent list-knowledge-bases
```

## Cost Savings

Destroying these resources will stop charges for:

- Aurora Serverless v2 ACUs (Aurora Capacity Units)
- NAT Gateway hourly charges
- S3 storage
- VPC (if you're in a region that charges for VPCs)

## Re-deployment

To recreate the infrastructure after destruction:

```bash
# Stack1
cd stack1
terraform init
terraform apply

# Stack2 (update ARNs in main.tf first)
cd ../stack2
terraform init
terraform apply
```
