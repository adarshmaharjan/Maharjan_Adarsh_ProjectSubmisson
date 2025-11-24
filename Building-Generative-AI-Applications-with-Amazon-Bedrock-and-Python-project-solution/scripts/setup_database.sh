#!/bin/bash

# Aurora cluster ARN and secret ARN
CLUSTER_ARN="arn:aws:rds:us-west-2:524734461030:cluster:my-aurora-serverless"
SECRET_ARN="arn:aws:secretsmanager:us-west-2:524734461030:secret:my-aurora-serverless-gcXBsC"
DATABASE_NAME="myapp"
REGION="us-west-2"

echo "Setting up Aurora database for Bedrock Knowledge Base..."

# Create vector extension
echo "Creating vector extension..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "CREATE EXTENSION IF NOT EXISTS vector;" \
    --region "$REGION"

# Create schema
echo "Creating bedrock_integration schema..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "CREATE SCHEMA IF NOT EXISTS bedrock_integration;" \
    --region "$REGION"

# Create bedrock_user role
echo "Creating bedrock_user role..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "DO \$\$ BEGIN CREATE ROLE bedrock_user LOGIN; EXCEPTION WHEN duplicate_object THEN RAISE NOTICE 'Role already exists'; END \$\$;" \
    --region "$REGION"

# Grant permissions
echo "Granting permissions to bedrock_user..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "GRANT ALL ON SCHEMA bedrock_integration to bedrock_user;" \
    --region "$REGION"

# Set session authorization
echo "Setting session authorization..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "SET SESSION AUTHORIZATION bedrock_user;" \
    --region "$REGION"

# Create table
echo "Creating bedrock_kb table..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "CREATE TABLE IF NOT EXISTS bedrock_integration.bedrock_kb (id uuid PRIMARY KEY, embedding vector(1536), chunks text, metadata json);" \
    --region "$REGION"

# Create index
echo "Creating index on embedding column..."
aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database "$DATABASE_NAME" \
    --sql "CREATE INDEX IF NOT EXISTS bedrock_kb_embedding_idx ON bedrock_integration.bedrock_kb USING hnsw (embedding vector_cosine_ops);" \
    --region "$REGION"

echo "Database setup complete!"
