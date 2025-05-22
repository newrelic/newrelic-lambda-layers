import logging
import os

from newrelic.common.encoding_utils import (
    json_encode,
    serverless_payload_encode,
)

try:
    from newrelic.core.agent_protocol import ServerlessModeProtocol
except ImportError:
    ServerlessModeProtocol = None

from newrelic.core.data_collector import ServerlessModeSession

NAMED_PIPE_PATH = "/tmp/newrelic-telemetry"

logger = logging.getLogger(__name__)


if ServerlessModeProtocol is not None:
    # New Relic Agent >=5.16
    def protocol_finalize(self):
        for key in self.configuration.aws_lambda_metadata:
            if key not in self._metadata:
                self._metadata[key] = self.configuration.aws_lambda_metadata[key]

        data = self.client.finalize()

        payload = {
            "metadata": self._metadata,
            "data": data,
        }

        encoded = serverless_payload_encode(payload)

        if os.path.exists(NAMED_PIPE_PATH):
            payload = json_encode((1, "NR_LAMBDA_MONITORING", encoded))
            try:
                with open(NAMED_PIPE_PATH, "w") as named_pipe:
                    named_pipe.write(payload)
            except IOError as e:
                logger.error(
                    "Failed to write to named pipe %s: %s" % (NAMED_PIPE_PATH, e)
                )
        else:
            # We will arbitrarily limit the size of the payload to 255KB.  This
            # is more than enough buffer to be able to send the data to CloudWatch,
            # even with the addition of metadata and other information.
            #
            # Note: Cloudwatch Logs and Cloudwatch Agent have different limits.
            # Lambda functions automatically send logs and metrics to CloudWatch
            # Logs, so the 256KB limit applies.  Cloudwatch Agent, however, has a
            # 1MB limit on the size of a single log event since April 2025.
            if os.getenv("NEW_RELIC_TO_CLOUDWATCH_MODE", False):
                while len(encoded) > (255 * 1024):
                    payload = json_encode((1, "NR_LAMBDA_MONITORING", encoded[:(255 * 1024)]))
                    print(payload)
                    encoded = encoded[(255 * 1024):]
        
            # Either Cloudwatch logging is not enabled, or the payload is small 
            # enough to be sent in a single log event to Cloudwatch.  In either 
            # case, we can send the entire payload in a single log event.   
            payload = json_encode((1, "NR_LAMBDA_MONITORING", encoded))
            print(payload)

            return payload

    ServerlessModeProtocol.finalize = protocol_finalize

else:
    # New Relic Agent <5.16
    def session_finalize(self):
        encoded = serverless_payload_encode(self.payload)
        payload = json_encode((1, "NR_LAMBDA_MONITORING", encoded))

        if os.path.exists(NAMED_PIPE_PATH):
            try:
                with open(NAMED_PIPE_PATH, "w") as named_pipe:
                    named_pipe.write(payload)
            except IOError as e:
                logger.error(
                    "Failed to write to named pipe %s: %s" % (NAMED_PIPE_PATH, e)
                )
        else:
            print(payload)

        # Clear data after sending
        self._data.clear()
        return payload

    ServerlessModeSession.finalize = session_finalize
