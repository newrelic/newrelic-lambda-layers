package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.newrelic.opentracing.aws.LambdaTracing;


public class RequestHandlerWrapper implements RequestHandler<Object, Object> {

    @Override
    public Object handleRequest(Object input, Context context) {
        return LambdaTracing.instrument(
                input,
                context,
                HandlerSetup.requestHandler::handleRequest
        );
    }
}
