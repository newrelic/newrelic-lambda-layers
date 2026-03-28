package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.newrelic.opentracing.aws.StreamLambdaTracing;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class StreamHandlerWrapper implements RequestStreamHandler {

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException {
        StreamLambdaTracing.instrument(
                input,
                output,
                context,
                HandlerSetup.requestStreamHandler
        );
    }
}
