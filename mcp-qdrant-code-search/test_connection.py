#!/usr/bin/env python3
"""Simple test script to verify Qdrant connection and basic functionality"""
import json
import requests
import sys

def test_qdrant_connection():
    """Test connection to Qdrant instance"""
    try:
        response = requests.get("http://localhost:6333/collections")
        if response.status_code == 200:
            data = response.json()
            collections = data.get('result', {}).get('collections', [])
            print(f"✅ Qdrant connection successful!")
            print(f"Found {len(collections)} collections:")
            for collection in collections:
                print(f"  - {collection['name']}")
            return True
        else:
            print(f"❌ Qdrant connection failed: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Qdrant connection failed: {str(e)}")
        return False

def test_collection_info():
    """Test getting collection info"""
    try:
        # Get the first collection for testing
        response = requests.get("http://localhost:6333/collections")
        collections = response.json()['result']['collections']
        
        if not collections:
            print("No collections found for testing")
            return False
        
        collection_name = collections[0]['name']
        print(f"\n📊 Testing collection info for: {collection_name}")
        
        response = requests.get(f"http://localhost:6333/collections/{collection_name}")
        if response.status_code == 200:
            info = response.json()['result']
            print(f"  Vectors: {info.get('vectors_count', 0)}")
            print(f"  Status: {info.get('status', 'unknown')}")
            
            config = info.get('config', {})
            if config:
                params = config.get('params', {})
                vectors_config = params.get('vectors', {})
                print(f"  Vector size: {vectors_config.get('size', 'unknown')}")
                print(f"  Distance: {vectors_config.get('distance', 'unknown')}")
            return True
        else:
            print(f"❌ Failed to get collection info: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Collection info test failed: {str(e)}")
        return False

def test_sample_search():
    """Test a sample vector search"""
    try:
        # Get collections
        response = requests.get("http://localhost:6333/collections")
        collections = response.json()['result']['collections']
        
        if not collections:
            print("No collections found for search testing")
            return False
        
        collection_name = collections[0]['name']
        print(f"\n🔍 Testing search in collection: {collection_name}")
        
        # Get collection info to understand vector size
        response = requests.get(f"http://localhost:6333/collections/{collection_name}")
        info = response.json()['result']
        vector_size = info['config']['params']['vectors']['size']
        
        # Create a dummy search vector (all zeros)
        dummy_vector = [0.0] * vector_size
        
        search_data = {
            "vector": dummy_vector,
            "limit": 3,
            "with_payload": True,
            "with_vector": False
        }
        
        response = requests.post(
            f"http://localhost:6333/collections/{collection_name}/points/search",
            json=search_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            results = response.json()['result']
            print(f"  Found {len(results)} results")
            if results:
                first_result = results[0]
                payload = first_result.get('payload', {})
                print(f"  Sample result: {payload.get('filePath', 'unknown file')}")
                print(f"  Score: {first_result.get('score', 0):.4f}")
            return True
        else:
            print(f"❌ Search test failed: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Search test failed: {str(e)}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing MCP Qdrant Code Search Server\n")
    
    # Test 1: Connection
    if not test_qdrant_connection():
        print("\n❌ Cannot proceed without Qdrant connection")
        sys.exit(1)
    
    # Test 2: Collection info
    test_collection_info()
    
    # Test 3: Sample search
    test_sample_search()
    
    print(f"\n✅ Basic tests completed!")
    print(f"\n📋 Next steps:")
    print(f"1. Install MCP dependencies in a virtual environment")
    print(f"2. Configure Claude Code to use this MCP server")
    print(f"3. Test indexing and searching with real codebases")

if __name__ == "__main__":
    main()