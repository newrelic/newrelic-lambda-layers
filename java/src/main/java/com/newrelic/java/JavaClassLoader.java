package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.*;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.MapperFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.reflect.Method;

public class JavaClassLoader {

    private static final MethodHandles.Lookup publicLookup = MethodHandles.publicLookup();
    private static final MethodType methodType = MethodType.methodType(Object.class, Object.class, Context.class);
    private static final ObjectMapper mapper = new ObjectMapper().configure(MapperFeature.ACCEPT_CASE_INSENSITIVE_PROPERTIES, true)
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .enable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS);

    private static Class inputType;
    private static MethodHandle methodHandle;

    private JavaClassLoader(Class inputType, MethodHandle methodHandle) {
        this.inputType = inputType;
        this.methodHandle = methodHandle;
    }

    static JavaClassLoader initializeClassLoader(String className, String methodName) throws ReflectiveOperationException {
        ClassLoader classLoader = JavaClassLoader.class.getClassLoader();
        Class loadedClass = classLoader.loadClass(className);
        Class methodInputType = null;

        for (Method method : loadedClass.getMethods()) {
            if (isUserHandlerMethod(method, className, methodName) == true) {
                methodInputType = method.getParameterTypes()[0];
                break;
            }
        }

        Object classInstance = loadedClass.getDeclaredConstructor().newInstance();
        MethodHandle methodHandle = publicLookup.findVirtual(loadedClass, methodName, methodType).bindTo(classInstance);

        return new JavaClassLoader(methodInputType, methodHandle);
    }

    public Object invokeClassMethod(Object inputParam, Context contextParam) {
        try {
            Object handlerType = mappingInputToHandlerType(inputParam, inputType);
            return methodHandle.invokeWithArguments(handlerType, contextParam);
        } catch (Throwable e) {
            throw new RuntimeException("Error occurred while invoking handler method: " + e);
        }
    }

    private static boolean isUserHandlerMethod(Method method, String className, String methodName) {
        // TODO is context required? Do we want to check for that here?
        if (method.toString().contains(className) &&
                method.getName().equals(methodName) &&
                method.getParameterTypes().length == 2 &&
                !(method.isBridge() || method.isSynthetic()) &&
                method.getParameterTypes()[1].isAssignableFrom(Context.class)) {
            return true;
        }
        return false;
    }

    private Object mappingInputToHandlerType(Object inputParam, Class inputType) {
        if (inputType.isAssignableFrom(Integer.class)) {
            return inputParam;
        } else if (inputType.isAssignableFrom(String.class)) {
            return inputParam;
        }
        return mapper.convertValue(inputParam, inputType);
    }
}

