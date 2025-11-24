#!/bin/bash

# Create the GIN index on the chunks column
aws rds-data execute-statement \
    --resource-arn "arn:aws:rds:us-west-2:524734461030:cluster:my-aurora-serverless" \
    --secret-arn "arn:aws:secretsmanager:us-west-2:524734461030:secret:my-aurora-serverless-Zirynx" \
    --database "myapp" \
    --region us-west-2 \
    --sql "CREATE INDEX IF NOT EXISTS bedrock_kb_chunks_idx ON bedrock_integration.bedrock_kb USING gin (to_tsvector('english', chunks));"

echo "Index creation command executed"
