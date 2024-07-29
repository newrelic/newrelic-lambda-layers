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
