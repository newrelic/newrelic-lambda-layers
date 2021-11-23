package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;

import java.util.function.BiFunction;

public class BiFunctionHandlerWithStringInput implements BiFunction<String, Context, String> {

    public static final String RESPONSE_PREFIX = "Hello ";

    @Override
    public String apply(String s, Context context) {
        return RESPONSE_PREFIX + s;
    }

}
