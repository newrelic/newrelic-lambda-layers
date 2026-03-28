package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.newrelic.opentracing.LambdaTracer;
import io.opentracing.Tracer;
import io.opentracing.util.GlobalTracer;

public class HandlerSetup {

    public static final String HANDLER_ENV_VAR = "NEW_RELIC_LAMBDA_HANDLER";

    public static RequestHandler<Object, Object> requestHandler;
    public static RequestStreamHandler requestStreamHandler;

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

}
