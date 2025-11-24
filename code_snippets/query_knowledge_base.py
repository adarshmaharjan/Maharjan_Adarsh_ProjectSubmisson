def query_knowledge_base(query, kb_id):
    try:
        print(f"Querying Knowledge Base {kb_id} with query: {query}")
        response = bedrock_kb.retrieve(
            knowledgeBaseId=kb_id,
            retrievalQuery={"text": query},
            retrievalConfiguration={
                "vectorSearchConfiguration": {"numberOfResults": 3}
            },
        )
        results = response.get("retrievalResults", [])
        print(f"Retrieved {len(results)} results from Knowledge Base")
        return results
    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_message = e.response.get("Error", {}).get("Message", str(e))
        print(f"Error querying Knowledge Base: [{error_code}] {error_message}")
        print(f"Full error: {e}")
        return []
    except Exception as e:
        print(f"Unexpected error querying Knowledge Base: {e}")
        return []
