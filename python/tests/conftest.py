import os
import subprocess
from threading import Timer, Event

import pytest


CWD = os.path.dirname(__file__)
SERVERLESS = os.path.realpath(os.path.join(CWD, "../node_modules/serverless/bin/serverless.js"))
TIMEOUT=60


@pytest.fixture(scope="session", autouse=True)
def start_serverless_offline():
    with subprocess.Popen([SERVERLESS, "offline", "start"], cwd=CWD, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
        timed_out = Event()
        def timeout():
            process.kill()
            timed_out.set()
            raise RuntimeError("Timeout exceeded.")

        timer = Timer(TIMEOUT, timeout)
        try:
            timer.start()
            while not timed_out.is_set():
                line = process.stderr.readline().decode("utf-8")
                # Wait for server to be ready
                if 'Server ready:' in line:
                    break
        finally:
            timer.cancel()

        if timed_out.is_set():
            raise RuntimeError("Timed out waiting for serverless to start.")

        # Return ready server from fixture
        yield process

        # Kill process on completion
        process.kill()
