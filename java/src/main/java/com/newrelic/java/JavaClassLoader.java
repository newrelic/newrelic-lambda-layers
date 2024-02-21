package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.serialization.PojoSerializer;
import com.amazonaws.services.lambda.runtime.serialization.events.LambdaEventSerializers;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.joda.JodaModule;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.reflect.Method;

public class JavaClassLoader implements RequestHandler<Object, Object> {

    private interface UnsafeHandler {

        Object handle(Object input, Context context) throws Throwable;

    }

    private final ObjectMapper mapper = new ObjectMapper().configure(MapperFeature.ACCEPT_CASE_INSENSITIVE_PROPERTIES, true)
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .enable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS)
            .registerModule(new JodaModule());

    private final Class<?> inputType;
    private final UnsafeHandler executor;

    static JavaClassLoader initializeRequestHandler(Class<?> loadedClass, String methodName) throws ReflectiveOperationException {
        Class<?> methodReturnType = Object.class;
        Class<?> methodInputType = Object.class;
        Class<?> methodContextType = null;
        for (Method method : loadedClass.getMethods()) {
            if (isUserHandlerMethod(method, methodName, loadedClass)) {
                methodReturnType = method.getReturnType();
                methodInputType = method.getParameterTypes()[0];
                if (method.getParameterTypes().length == 2) {
                    methodContextType = method.getParameterTypes()[1];
                }
                break;
            }
        }

        Object classInstance = loadedClass.getDeclaredConstructor().newInstance();

        MethodHandle methodHandle = MethodHandles.publicLookup().findVirtual(
                loadedClass,
                methodName,
                getMethodType(methodReturnType, methodInputType, methodContextType)
        ).bindTo(classInstance);

        return new JavaClassLoader(methodInputType, methodHandle, methodContextType != null);
    }

    private static MethodType getMethodType(Class<?> methodReturnType, Class<?> methodInputType, Class<?> methodContextType) {
        if (methodContextType == null) {
            return MethodType.methodType(methodReturnType, methodInputType);
        }
        return MethodType.methodType(methodReturnType, methodInputType, methodContextType);
    }

    // RequestHandler implementation constructor
    private JavaClassLoader(Class<?> inputType, MethodHandle methodHandle, boolean hasTwoArguments) {
        this.inputType = inputType;
        this.executor = hasTwoArguments
                ? methodHandle::invokeWithArguments
                : (handlerType, contextParam) -> methodHandle.invokeWithArguments(handlerType);
    }

    @Override
    public Object handleRequest(Object inputParam, Context contextParam) {
        try {
            return executor.handle(mappingInputToHandlerType(inputParam, inputType), contextParam);
        } catch (Throwable e) {
            throw new RuntimeException("Error occurred while invoking handler method: " + e, e);
        }
    }

    private static boolean isUserHandlerMethod(Method method, String methodName, Class<?> loadedClass) {
        if (!method.getDeclaringClass().isAssignableFrom(loadedClass)) {
            return false;
        }

        if (!method.getName().equals(methodName)) {
            return false;
        }

        if (method.isBridge() || method.isSynthetic()) {
            return false;
        }

        if (method.getParameterTypes().length == 1) {
            return true;
        }

        return method.getParameterTypes().length == 2 && (
                method.getParameterTypes()[1].isAssignableFrom(Context.class) || Object.class.equals(method.getParameterTypes()[1])
        );
    }

    private Object mappingInputToHandlerType(Object inputParam, Class<?> inputType) throws JsonProcessingException {
        if (inputType.isAssignableFrom(Number.class) || inputType.isAssignableFrom(String.class)) {
            return inputParam;
        } else if (LambdaEventSerializers.isLambdaSupportedEvent(inputType.getName())) {
            PojoSerializer<?> serializer = LambdaEventSerializers.serializerFor(inputType, JavaClassLoader.class.getClassLoader());
            String inputParamString = mapper.writeValueAsString(inputParam);
            return serializer.fromJson(inputParamString);
        }
        return inputParam instanceof CharSequence ? mapper.readValue(inputParam.toString(), inputType) : mapper.convertValue(inputParam, inputType);
    }
}

