import functools
import json
import os
import re

import newrelic.agent
import newrelic.core.attribute

try:
    from urllib import urlencode
except ImportError:
    from urllib.parse import urlencode

# noinspection PyProtectedMember
newrelic.core.attribute._TRANSACTION_EVENT_DEFAULT_ATTRIBUTES.update(
    {
        "aws.lambda.eventSource.account",
        "aws.lambda.eventSource.accountId",
        "aws.lambda.eventSource.apiId",
        "aws.lambda.eventSource.bucketName",
        "aws.lambda.eventSource.date",
        "aws.lambda.eventSource.eventName",
        "aws.lambda.eventSource.eventTime",
        "aws.lambda.eventSource.eventType",
        "aws.lambda.eventSource.id",
        "aws.lambda.eventSource.length",
        "aws.lambda.eventSource.messageId",
        "aws.lambda.eventSource.objectKey",
        "aws.lambda.eventSource.objectSequencer",
        "aws.lambda.eventSource.objectSize",
        "aws.lambda.eventSource.region",
        "aws.lambda.eventSource.resource",
        "aws.lambda.eventSource.resourceId",
        "aws.lambda.eventSource.resourcePath",
        "aws.lambda.eventSource.returnPath",
        "aws.lambda.eventSource.stage",
        "aws.lambda.eventSource.time",
        "aws.lambda.eventSource.timestamp",
        "aws.lambda.eventSource.topicArn",
        "aws.lambda.eventSource.type",
        "aws.lambda.eventSource.xAmzId2",
        "aws.lambda.functionVersion",
        "request.headers.host",
    }
)

COLD_START_RECORDED = False
MEGABYTE_IN_BYTES = 2 ** 20
PATH_SPLIT_REGEX = re.compile(r"[.\[]")

# We're using JSON here to maximize cross-agent consistency.
with open(os.path.join(os.path.dirname(__file__), "event-sources.json")) as f:
    EVENT_TYPE_INFO = json.load(f)


def path_match(path, obj):
    return path_get(path, obj) is not None


def path_get(path, obj):
    path = PATH_SPLIT_REGEX.split(path)

    pos = obj
    for segment in path:
        segment = segment.rstrip("]")
        try:
            if segment.isdigit():
                segment = int(segment)
            elif segment == "length":
                return len(pos)
            pos = pos[segment]
        except IndexError:
            return None
        except KeyError:
            return None
    return pos


def extract_event_source_arn(event):
    try:
        # Firehose
        arn = event.get("streamArn") or event.get("deliveryStreamArn")

        if not arn:
            # Dynamo, Kinesis, S3, SNS, SQS
            record = path_get("Records[0]", event)

            if record:
                arn = (
                    record.get("eventSourceARN")
                    or record.get("EventSubscriptionArn")
                    or path_get("s3.bucket.arn", record)
                )
        # ALB
        if not arn:
            arn = path_get("requestContext.elb.targetGroupArn", event)
        # CloudWatch events
        if not arn:
            arn = path_get("resources[0]", event)

        if arn:
            return newrelic.core.attribute.truncate(str(arn))
        return None
    except Exception:
        pass


def detect_event_type(event):
    if isinstance(event, dict):
        for k, type_info in EVENT_TYPE_INFO.items():
            if all(path_match(path, event) for path in type_info["required_keys"]):
                return type_info
    return None


def get_attributes_for_event_type(event_type, event):
    attr_names_and_values = {}
    event_type_attributes = event_type["attributes"]
    for attr_name, path in event_type_attributes.items():
        attr = path_get(path, event)
        if attr is not None:
            attr_names_and_values[attr_name] = attr
    return attr_names_and_values


def LambdaHandlerWrapper(wrapped, application=None, name=None, group=None):
    def set_agent_attr(transaction, key, value):
        # noinspection PyProtectedMember
        transaction._add_agent_attribute(key, value)

    def _nr_lambda_handler_wrapper_(wrapped, instance, args, kwargs):
        # Check to see if any transaction is present, even an inactive
        # one which has been marked to be ignored or which has been
        # stopped already.

        transaction = newrelic.agent.current_transaction(active_only=False)

        if transaction:
            return wrapped(*args, **kwargs)

        try:
            event, context = args[:2]
        except Exception:
            return wrapped(*args, **kwargs)

        target_application = application

        # If application has an activate() method we assume it is an
        # actual application. Do this rather than check type so that
        # can easily mock it for testing.

        # FIXME Should this allow for multiple apps if a string.

        if not hasattr(application, "activate"):
            target_application = newrelic.agent.application(application)

        try:
            if "httpMethod" in event:
                request_method = event["httpMethod"]
                request_path = event["path"]
            else:
                request_method = event["requestContext"]["http"]["method"]
                request_path = event["requestContext"]["http"]["path"]

            headers = None
            if "headers" in event:
                headers = event["headers"]
            elif "multiValueHeaders" in event:
                headers = {
                    k: ", ".join(v) for k, v in event["multiValueHeaders"].items()
                }
            background_task = False
            try:
                query_string = None
                if "queryStringParameters" in event:
                    query_string = urlencode(event["queryStringParameters"], True)
                elif "multiValueQueryStringParameters" in event:
                    query_string = urlencode(
                        event["multiValueQueryStringParameters"], True
                    )
            except Exception:
                query_string = None
        except Exception:
            request_method = None
            request_path = None
            headers = None
            query_string = None
            background_task = True
        

        request_id = getattr(context, "aws_request_id", None)
        aws_arn = getattr(context, "invoked_function_arn", None)
        function_version = getattr(context, "function_version", None)
        event_source = extract_event_source_arn(event)
        event_type = detect_event_type(event)

        apm_lambda_mode = os.environ.get("NEW_RELIC_APM_LAMBDA_MODE", "false").lower()
        if apm_lambda_mode == "true":
            trigger = event_type["name"].upper() + " " if event_type else ""
            transaction_name = trigger + getattr(context, "function_name", None)
        else:
            transaction_name = name or getattr(context, "function_name", None)

        transaction = newrelic.agent.WebTransaction(
            target_application,
            transaction_name,
            group=group,
            request_method=request_method,
            request_path=request_path,
            headers=headers,
            query_string=query_string,
        )

        transaction.background_task = background_task

        if request_id:
            set_agent_attr(transaction, "aws.requestId", request_id)
        if aws_arn:
            set_agent_attr(transaction, "aws.lambda.arn", aws_arn)
        if function_version:
            set_agent_attr(transaction, "aws.lambda.functionVersion", function_version)
        if event_source:
            set_agent_attr(transaction, "aws.lambda.eventSource.arn", event_source)
        if event_type:
            event_type_name = event_type["name"]
            set_agent_attr(
                transaction, "aws.lambda.eventSource.eventType", event_type_name
            )

            # Save event-specific attributes
            for attr_name, attr in get_attributes_for_event_type(
                event_type, event
            ).items():
                set_agent_attr(transaction, attr_name, attr)

        # COLD_START_RECORDED is initialized to "False" when the container
        # first starts up, and will remain that way until the below lines
        # of code are encountered during the first transaction after the cold
        # start. We record this occurence on the transaction so that an
        # attribute is created, and then set COLD_START_RECORDED to False so
        # that the attribute is not created again during future invocations of
        # this container.

        global COLD_START_RECORDED
        if COLD_START_RECORDED is False:
            set_agent_attr(transaction, "aws.lambda.coldStart", True)
            COLD_START_RECORDED = True

        settings = newrelic.agent.global_settings()
        if aws_arn:
            settings.aws_lambda_metadata["arn"] = aws_arn
        if function_version:
            settings.aws_lambda_metadata["function_version"] = function_version

        with transaction:
            result = wrapped(*args, **kwargs)

            if not background_task:
                try:
                    status_code = result.get("statusCode")
                    response_headers = result.get("headers")

                    try:
                        response_headers = response_headers.items()
                    except Exception:
                        response_headers = None

                    transaction.process_response(status_code, response_headers)
                except Exception:
                    pass

            return result

    return newrelic.agent.FunctionWrapper(wrapped, _nr_lambda_handler_wrapper_)


def lambda_handler(application=None, name=None, group=None):
    return functools.partial(
        LambdaHandlerWrapper, application=application, name=name, group=group
    )
