package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.github.stefanbirkner.systemlambda.SystemLambda;
import org.junit.Test;
import org.mockito.Mockito;

import java.io.InputStream;
import java.io.OutputStream;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

public class HandlerWrapperTest {

    @Test
    public void testRequestHandler() throws Exception {
        SystemLambda.withEnvironmentVariable(HandlerWrapper.HANDLER_ENV_VAR, RequestHandlerWithObjectInput.class.getName())
                .execute(() -> {
                    HandlerWrapper.setupHandlers();
                    assertEquals("Hello World", new HandlerWrapper().handleRequest(Input.create("World"), Mockito.mock(Context.class)));
                });
    }

    @Test
    public void testRequestWrongHandler() throws Exception {
        SystemLambda.withEnvironmentVariable(HandlerWrapper.HANDLER_ENV_VAR, RequestHandlerWithObjectInput.class.getName())
                .execute(() -> {
                    HandlerWrapper.setupHandlers();
                    assertThrows(RuntimeException.class, () ->
                            new HandlerWrapper().handleStreamsRequest(Mockito.mock(InputStream.class), Mockito.mock(OutputStream.class), Mockito.mock(Context.class))
                    );
                });
    }

    @Test
    public void testRequestStreamHandler() throws Exception {
        SystemLambda.withEnvironmentVariable(HandlerWrapper.HANDLER_ENV_VAR, TestStreamingRequestHandler.class.getName())
                .execute(() -> {
                    HandlerWrapper.setupHandlers();
                    new HandlerWrapper().handleStreamsRequest(Mockito.mock(InputStream.class), Mockito.mock(OutputStream.class), Mockito.mock(Context.class));
                });
    }

    @Test
    public void testRequestWrongStreamHandler() throws Exception {
        SystemLambda.withEnvironmentVariable(HandlerWrapper.HANDLER_ENV_VAR, TestStreamingRequestHandler.class.getName())
                .execute(() -> {
                    HandlerWrapper.setupHandlers();
                    assertThrows(RuntimeException.class, () -> new HandlerWrapper().handleRequest(Input.create("World"), Mockito.mock(Context.class)));
                });
    }

}
