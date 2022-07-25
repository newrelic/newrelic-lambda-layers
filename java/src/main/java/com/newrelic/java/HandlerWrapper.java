package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.newrelic.opentracing.LambdaTracer;
import com.newrelic.opentracing.aws.LambdaTracing;
import com.newrelic.opentracing.aws.StreamLambdaTracing;
import io.opentracing.Tracer;
import io.opentracing.util.GlobalTracer;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class HandlerWrapper {

    public static final String HANDLER_ENV_VAR = "NEW_RELIC_LAMBDA_HANDLER";

    private static RequestHandler<Object, Object> requestHandler;
    private static RequestStreamHandler requestStreamHandler;

    static {
        // Obtain an instance of the OpenTracing Tracer of your choice
        Tracer tracer = LambdaTracer.INSTANCE;
        // Register your tracer as the Global Tracer
        GlobalTracer.registerIfAbsent(tracer);

        // Set up handlers
        setupHandlers();
    }

    static void setupHandlers() {
        String handler = System.getenv(HANDLER_ENV_VAR);
        String[] parts = handler.split("::");
        String handlerClass = parts[0];
        String handlerMethod = parts.length == 2 ? parts[1] : "handleRequest";

        try {
            Class<?> loadedClass = JavaClassLoader.class.getClassLoader().loadClass(handlerClass);

            boolean isRequestStreamHandler = RequestStreamHandler.class.isAssignableFrom(loadedClass);
            requestHandler = isRequestStreamHandler
                    ? (input, context) -> {
                        throw new IllegalStateException("" + handlerClass + " is RequestStreamHandler, use handleStreamsRequest instead");
                    }
                    : JavaClassLoader.initializeRequestHandler(loadedClass, handlerMethod);
            requestStreamHandler = isRequestStreamHandler
                    ? (RequestStreamHandler) loadedClass.getDeclaredConstructor().newInstance()
                    : (input, output, context) -> {
                        throw new IllegalStateException("" + handlerClass + " is not RequestStreamHandler, use handleRequest instead");
                    };

        } catch (ReflectiveOperationException e) {
            throw new RuntimeException("Error occurred during initialization of javaClassLoader:", e);
        }
    }

    public Object handleRequest(Object input, Context context) {
        return LambdaTracing.instrument(
                input,
                context,
                requestHandler::handleRequest
        );
    }

    public void handleStreamsRequest(InputStream input, OutputStream output, Context context) throws IOException {
        StreamLambdaTracing.instrument(
                input,
                output,
                context,
                requestStreamHandler
        );
    }

}
