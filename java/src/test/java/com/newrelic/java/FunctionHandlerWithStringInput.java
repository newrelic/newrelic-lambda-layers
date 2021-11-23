package com.newrelic.java;

import java.util.function.Function;

public class FunctionHandlerWithStringInput implements Function<String, String> {

    public static final String RESPONSE_PREFIX = "Hello ";

    @Override
    public String apply(String s) {
        return RESPONSE_PREFIX + s;
    }

}
