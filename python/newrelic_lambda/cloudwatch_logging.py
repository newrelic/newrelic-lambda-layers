import logging
import os
import boto3
from time import time

logger = logging.getLogger(__name__)

def put_log_to_cloudwatch(payload):
    logs_client = boto3.client('logs')

    log_group_name = os.getenv("AWS_LAMBDA_LOG_GROUP_NAME", "")
    log_stream_name = os.getenv("AWS_LAMBDA_LOG_STREAM_NAME", "")

    def ensure_log_stream_exists(log_group_name, log_stream_name):
        try:
            logs_client.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
        except Exception as e:
            logger.error(f"Failed to create log stream {log_stream_name} in log group {log_group_name}: {e}")

    ensure_log_stream_exists(log_group_name, log_stream_name)

    log_event = {
        'timestamp': int(time() * 1000),
        'message': payload,
    }

    logs_client.put_log_events(
        logGroupName=log_group_name,
        logStreamName=log_stream_name,
        logEvents=[log_event]
    )
    