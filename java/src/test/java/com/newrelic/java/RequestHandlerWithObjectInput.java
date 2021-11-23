package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class RequestHandlerWithObjectInput implements RequestHandler<Input, String> {

    public static final String RESPONSE_PREFIX = "Hello ";

    @Override
    public String handleRequest(Input s, Context context) {
        return RESPONSE_PREFIX + s.getMessage();
    }

}
