#!/usr/bin/env python3
"""
Test script to verify Knowledge Base connectivity and query functionality
"""

import boto3
from botocore.exceptions import ClientError
import json


def test_knowledge_base():
    print("=" * 60)
    print("Knowledge Base Diagnostic Script")
    print("=" * 60)

    # Initialize clients
    bedrock_kb = boto3.client(
        service_name="bedrock-agent-runtime", region_name="us-west-2"
    )
    bedrock_agent = boto3.client(service_name="bedrock-agent", region_name="us-west-2")

    # Step 1: List all Knowledge Bases
    print("\n1. Listing all Knowledge Bases...")
    try:
        response = bedrock_agent.list_knowledge_bases()
        kbs = response.get("knowledgeBaseSummaries", [])

        if not kbs:
            print("   ❌ No Knowledge Bases found in us-west-2")
            return

        print(f"   ✓ Found {len(kbs)} Knowledge Base(s):")
        for kb in kbs:
            kb_id = kb["knowledgeBaseId"]
            kb_name = kb["name"]
            kb_status = kb["status"]
            print(f"     - ID: {kb_id}")
            print(f"       Name: {kb_name}")
            print(f"       Status: {kb_status}")

        # Use the first KB ID for testing
        test_kb_id = kbs[0]["knowledgeBaseId"]
        print(f"\n   Using KB ID: {test_kb_id} for testing")

    except ClientError as e:
        print(f"   ❌ Error listing Knowledge Bases: {e}")
        return

    # Step 2: Check Data Sources
    print(f"\n2. Checking Data Sources for KB {test_kb_id}...")
    try:
        response = bedrock_agent.list_data_sources(knowledgeBaseId=test_kb_id)
        data_sources = response.get("dataSourceSummaries", [])

        if not data_sources:
            print("   ⚠️  No Data Sources found")
        else:
            print(f"   ✓ Found {len(data_sources)} Data Source(s):")
            for ds in data_sources:
                ds_id = ds["dataSourceId"]
                ds_name = ds["name"]
                ds_status = ds["status"]
                print(f"     - ID: {ds_id}")
                print(f"       Name: {ds_name}")
                print(f"       Status: {ds_status}")

    except ClientError as e:
        print(f"   ⚠️  Error listing Data Sources: {e}")

    # Step 3: Test Query
    print(f"\n3. Testing Knowledge Base Query...")
    test_query = "What is heavy machinery?"
    print(f"   Query: '{test_query}'")

    try:
        response = bedrock_kb.retrieve(
            knowledgeBaseId=test_kb_id,
            retrievalQuery={"text": test_query},
            retrievalConfiguration={
                "vectorSearchConfiguration": {"numberOfResults": 3}
            },
        )

        results = response.get("retrievalResults", [])
        print(f"   ✓ Query successful! Retrieved {len(results)} result(s)")

        if results:
            print("\n   Results:")
            for i, result in enumerate(results, 1):
                content = result.get("content", {}).get("text", "No content")
                score = result.get("score", 0)
                print(f"\n   Result {i} (Score: {score:.4f}):")
                print(
                    f"   {content[:200]}..." if len(content) > 200 else f"   {content}"
                )
        else:
            print(
                "   ⚠️  No results returned. Knowledge Base might be empty or not synced."
            )

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_message = e.response.get("Error", {}).get("Message", str(e))
        print(f"   ❌ Query failed: [{error_code}] {error_message}")

        if error_code == "ResourceNotFoundException":
            print("\n   💡 Troubleshooting:")
            print("      - Verify the Knowledge Base ID is correct")
            print("      - Ensure the Knowledge Base exists in us-west-2 region")
        elif error_code == "AccessDeniedException":
            print("\n   💡 Troubleshooting:")
            print("      - Check your IAM permissions")
            print(
                "      - Required permissions: bedrock:Retrieve, bedrock:RetrieveAndGenerate"
            )

    print("\n" + "=" * 60)
    print("Diagnostic Complete")
    print("=" * 60)


if __name__ == "__main__":
    test_knowledge_base()
