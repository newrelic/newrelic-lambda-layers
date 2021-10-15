package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class RequestHandlerWithStringInput implements RequestHandler<String, String> {

    public static final String RESPONSE_PREFIX = "Hello ";

    @Override
    public String handleRequest(String s, Context context) {
        return RESPONSE_PREFIX + s;
    }

}
