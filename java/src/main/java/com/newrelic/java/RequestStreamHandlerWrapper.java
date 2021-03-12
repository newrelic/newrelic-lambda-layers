package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.newrelic.opentracing.LambdaTracer;
import com.newrelic.opentracing.aws.StreamLambdaTracing;
import io.opentracing.Tracer;
import io.opentracing.util.GlobalTracer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class RequestStreamHandlerWrapper implements RequestStreamHandler {
    static JavaClassLoader javaClassLoader;
    static {
        // Obtain an instance of the OpenTracing Tracer of your choice
        Tracer tracer = LambdaTracer.INSTANCE;
        // Register your tracer as the Global Tracer
        GlobalTracer.registerIfAbsent(tracer);

        String handler = System.getenv("NEW_RELIC_LAMBDA_HANDLER");
        String[] parts = handler.split("::");
        String handlerClass = parts[0];

        try {
            javaClassLoader = JavaClassLoader.initializeClassLoader(handlerClass);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException("Error occurred during initialization of javaStreamClassLoader: " + e);
        }
    }

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException {
        StreamLambdaTracing.instrument(
                input,
                output,
                context,
                javaClassLoader.getClassInstance()
        );
    }
}

