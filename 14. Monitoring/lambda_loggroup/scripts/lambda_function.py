import json

def lambda_handler(event, context):
    # Extract parameters from EventBridge
    message = event.get("message", "No message received")
    timestamp = event.get("timestamp", "No timestamp received")
    
    print(f"Received message: {message}")
    print(f"Received timestamp: {timestamp}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": message,
            "timestamp": timestamp
        })
    }
