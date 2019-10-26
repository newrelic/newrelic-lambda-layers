import imp
import os
import warnings

import newrelic.agent

os.environ.setdefault("NEW_RELIC_NO_CONFIG_FILE", "true")
os.environ.setdefault("NEW_RELIC_DISTRIBUTED_TRACING_ENABLED", "true")
os.environ.setdefault("NEW_RELIC_LOG", "stdout")
os.environ.setdefault("NEW_RELIC_LOG_ENABLED", "true")
os.environ.setdefault("NEW_RELIC_LOG_LEVEL", "info")
os.environ.setdefault("NEW_RELIC_SERVERLESS_MODE_ENABLED", "true")

newrelic.agent.initialize()
wrapped_handler = None


class IOpipeNoOp(object):
    def __call__(self, *args, **kwargs):
        warnings.warn(
            "Use of context.iopipe.* is no longer supported. "
            "Please see New Relic Python agent documentation here: "
            "https://docs.newrelic.com/docs/agents/python-agent"
        )

    def __getattr__(self, name):
        return IOpipeNoOp()


@newrelic.agent.lambda_handler()
def handler(event, context):
    context.iopipe = IOpipeNoOp()
    return get_wrapped_handler()(event, context)


def get_handler():
    if (
        "NEW_RELIC_LAMBDA_HANDLER" not in os.environ
        or not os.environ["NEW_RELIC_LAMBDA_HANDLER"]
    ):
        raise ValueError(
            "No value specified in NEW_RELIC_LAMBDA_HANDLER environment variable"
        )

    try:
        module_path, handler_name = os.environ["NEW_RELIC_LAMBDA_HANDLER"].rsplit(
            ".", 1
        )
    except ValueError:
        raise ValueError(
            "Improperly formated handler value: %s"
            % os.environ["NEW_RELIC_LAMBDA_HANDLER"]
        )

    module_path = module_path.replace("/", ".")
    file_handle, pathname, desc = None, None, None

    try:
        for segment in module_path.split("."):
            if pathname is not None:
                pathname = [pathname]

            file_handle, pathname, desc = imp.find_module(segment, pathname)

        if file_handle is None:
            module_type = desc[2]
            if module_type == imp.C_BUILTIN:
                raise ImportError(
                    "Cannot use built-in module %s as a handler module" % module_path
                )

        module = imp.load_module(module_path, file_handle, pathname, desc)
    except Exception:
        raise ImportError("Failed to import module: %s" % module_path)
    finally:
        if file_handle is not None:
            file_handle.close()

    try:
        handler = getattr(module, handler_name)
    except AttributeError:
        raise AttributeError("No handler %s in module %s" % (handler_name, module_path))

    return handler


def get_wrapped_handler():
    global wrapped_handler

    if not wrapped_handler:
        wrapped_handler = get_handler()

    return wrapped_handler
