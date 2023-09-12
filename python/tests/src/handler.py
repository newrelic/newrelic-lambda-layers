def handler(event, context):
    print("Running handler.")
    return {
        "statusCode": 200,
        "body": "{}"
    }