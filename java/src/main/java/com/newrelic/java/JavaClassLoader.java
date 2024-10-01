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
        Class<?> methodInputType = null;
        Class<?> methodContextType = null;
        int numberOfArguments = 0;
        for (Method method : loadedClass.getMethods()) {
            if (isUserHandlerMethod(method, methodName, loadedClass)) {
                methodReturnType = method.getReturnType();
                if (method.getParameterTypes().length == 1) {
                    methodInputType = method.getParameterTypes()[0];
                } else if (method.getParameterTypes().length == 2) {
                    methodInputType = method.getParameterTypes()[0];
                    methodContextType = method.getParameterTypes()[1];
                }
                numberOfArguments = method.getParameterTypes().length;
                break;
            }
        }

        Object classInstance = loadedClass.getDeclaredConstructor().newInstance();

        MethodHandle methodHandle = MethodHandles.publicLookup().findVirtual(
                loadedClass,
                methodName,
                getMethodType(methodReturnType, methodInputType, methodContextType)
        ).bindTo(classInstance);

        return new JavaClassLoader(methodInputType, methodHandle, numberOfArguments);
    }

    private static MethodType getMethodType(Class<?> methodReturnType, Class<?> methodInputType, Class<?> methodContextType) {
        if (methodInputType == null) {
            return MethodType.methodType(methodReturnType);
        } else if (methodContextType == null) {
            return MethodType.methodType(methodReturnType, methodInputType);
        }
        return MethodType.methodType(methodReturnType, methodInputType, methodContextType);
    }

    // RequestHandler implementation constructor
    private JavaClassLoader(Class<?> inputType, MethodHandle methodHandle, int numberOfArguments) {
        this.inputType = inputType;
        if (numberOfArguments == 0) {
            this.executor = (input, context) -> methodHandle.invoke();
        } else
        if (numberOfArguments == 1) {
            this.executor = (input, context) -> methodHandle.invokeWithArguments(input);
        } else {
            this.executor = methodHandle::invokeWithArguments;
        }
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

        if (method.getParameterTypes().length <= 1) {
            return true;
        }

        return method.getParameterTypes().length == 2 && (
                method.getParameterTypes()[1].isAssignableFrom(Context.class) || Object.class.equals(method.getParameterTypes()[1])
        );
    }

    private Object mappingInputToHandlerType(Object inputParam, Class<?> inputType) throws JsonProcessingException {
        if (inputType == null) {
            return inputParam;
        }
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

