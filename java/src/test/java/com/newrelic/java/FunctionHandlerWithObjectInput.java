package com.newrelic.java;

import java.util.function.Function;

public class FunctionHandlerWithObjectInput implements Function<Input, String> {

    public static final String RESPONSE_PREFIX = "Hello ";

    @Override
    public String apply(Input s) {
        return RESPONSE_PREFIX + s.getMessage();
    }

}
