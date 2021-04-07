package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.newrelic.opentracing.LambdaTracer;
import com.newrelic.opentracing.aws.LambdaTracing;
import io.opentracing.Tracer;
import io.opentracing.util.GlobalTracer;

public class RequestHandlerWrapper implements RequestHandler<Object, Object> {
    static JavaClassLoader javaClassLoader;
    static {
        // Obtain an instance of the OpenTracing Tracer of your choice
        Tracer tracer = LambdaTracer.INSTANCE;
        // Register your tracer as the Global Tracer
        GlobalTracer.registerIfAbsent(tracer);

        String handler = System.getenv("NEW_RELIC_LAMBDA_HANDLER");
        String[] parts = handler.split("::");
        String handlerClass = parts[0];
        String handlerMethod = parts.length == 2 ? parts[1] : "handleRequest";

        try {
             javaClassLoader = JavaClassLoader.initializeClassLoader(handlerClass, handlerMethod);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException("Error occurred during initialization of javaClassLoader: " + e);
        }
    }

    // Instrumentation for RequestHandler
    @Override
    public Object handleRequest(Object input, Context context) {
        return LambdaTracing.instrument(
                input,
                context,
                (event, ctx) -> javaClassLoader.invokeClassMethod(input, context)
        );
    }
}
