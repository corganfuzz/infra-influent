import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    untoched_bucket = os.environ.get('UNTOUCHED_BUCKET')
    processed_bucket = os.environ.get('PROCESSED_BUCKET')
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from pptx-modifier!',
            'untoched_bucket': untoched_bucket,
            'processed_bucket': processed_bucket,
            'timestamp': datetime.now().isoformat()
        })
    }
