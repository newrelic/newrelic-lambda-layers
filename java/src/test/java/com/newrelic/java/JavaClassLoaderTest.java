package com.newrelic.java;

import org.junit.Assert;
import org.junit.Test;

public class JavaClassLoaderTest {

    private static final String INPUT_AS_STRING = "{\"message\": \"World\"}";
    private static final Input INPUT_AS_OBJECT = Input.create("World");
    public static final String STRING_INPUT = "World";

    @Test
    public void testFunctionWithObjectHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(FunctionHandlerWithObjectInput.class, "apply");
        Assert.assertEquals("Hello World", loader.handleRequest(INPUT_AS_OBJECT, null));
    }

    @Test
    public void testFunctionWithObjectHandlerPassedAsJson() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(FunctionHandlerWithObjectInput.class, "apply");
        Assert.assertEquals("Hello World", loader.handleRequest(INPUT_AS_STRING, null));
    }

    @Test
    public void testFunctionWithStringHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(FunctionHandlerWithStringInput.class, "apply");
        Assert.assertEquals("Hello World", loader.handleRequest(STRING_INPUT, null));
    }

    @Test
    public void testBiFunctionWithObjectHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(BiFunctionHandlerWithObjectInput.class, "apply");
        Assert.assertEquals("Hello World", loader.handleRequest(INPUT_AS_OBJECT, null));
    }

    @Test
    public void testBiFunctionWithStringHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(BiFunctionHandlerWithStringInput.class, "apply");
        Assert.assertEquals("Hello World", loader.handleRequest(STRING_INPUT, null));
    }

    @Test
    public void testWithObjectRequestHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(RequestHandlerWithObjectInput.class, "handleRequest");
        Assert.assertEquals("Hello World", loader.handleRequest(INPUT_AS_OBJECT, null));
    }

    @Test
    public void testWithStringRequestHandler() throws ReflectiveOperationException {
        JavaClassLoader loader = JavaClassLoader.initializeRequestHandler(RequestHandlerWithStringInput.class, "handleRequest");
        Assert.assertEquals("Hello World", loader.handleRequest(STRING_INPUT, null));
    }

}
