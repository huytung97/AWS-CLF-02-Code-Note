def lambda_handler(event, context):
    print('Hello Lambda function')
    return {
        "statusCode": 200,
        "body": "Hello, from Lambda!"
    }
