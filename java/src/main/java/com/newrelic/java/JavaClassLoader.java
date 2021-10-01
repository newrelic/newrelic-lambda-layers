package com.newrelic.java;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
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

public class JavaClassLoader {

    private static final ClassLoader classLoader = JavaClassLoader.class.getClassLoader();
    private static final MethodHandles.Lookup publicLookup = MethodHandles.publicLookup();
    private static final MethodType methodType = MethodType.methodType(Object.class, Object.class, Context.class);
    private static final ObjectMapper mapper = new ObjectMapper().configure(MapperFeature.ACCEPT_CASE_INSENSITIVE_PROPERTIES, true)
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .enable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS)
            .registerModule(new JodaModule());

    private static Class inputType;
    private static MethodHandle methodHandle;
    private static RequestStreamHandler classInstance;

    static JavaClassLoader initializeClass(String className, String methodName) throws ReflectiveOperationException {
        Class loadedClass = classLoader.loadClass(className);
        if (RequestStreamHandler.class.isAssignableFrom(loadedClass)) {
            return initializeRequestStreamHandler(className, loadedClass);
        }
        return initializeRequestHandler(className, methodName, loadedClass);
    }

    // RequestStreamHandler implementation constructor
    private JavaClassLoader(RequestStreamHandler classInstance) {
        this.classInstance = classInstance;
    }

    // RequestStreamHandler initializeClassLoader
    static JavaClassLoader initializeRequestStreamHandler(String className, Class loadedClass) throws ReflectiveOperationException {
        RequestStreamHandler classInstance = (RequestStreamHandler) loadedClass.getDeclaredConstructor().newInstance();
        return new JavaClassLoader(classInstance);
    }

    public static RequestStreamHandler getClassInstance() {
        return classInstance;
    }

    // RequestHandler implementation constructor
    private JavaClassLoader(Class inputType, MethodHandle methodHandle) {
        this.inputType = inputType;
        this.methodHandle = methodHandle;
    }

    // RequestHandler initializeClassLoader
    static JavaClassLoader initializeRequestHandler(String className, String methodName, Class loadedClass) throws ReflectiveOperationException {
        Class methodInputType = null;
        for (Method method : loadedClass.getMethods()) {
            if (isUserHandlerMethod(method, className, methodName, loadedClass) == true) {
                methodInputType = method.getParameterTypes()[0];
                break;
            }
        }
        Object classInstance = loadedClass.getDeclaredConstructor().newInstance();
        MethodHandle methodHandle = publicLookup.findVirtual(loadedClass, methodName, methodType).bindTo(classInstance);
        return new JavaClassLoader(methodInputType, methodHandle);
    }

    public Object invokeClassMethod(Object inputParam, Context contextParam) {
        Object handlerType = mappingInputToHandlerType(inputParam, inputType);
        try {
            return methodHandle.invokeWithArguments(handlerType, contextParam);
        } catch (Throwable e) {
            throw new RuntimeException("Error occurred while invoking handler method: " + e);
        }
    }

    private static boolean isUserHandlerMethod(Method method, String className, String methodName, Class<?> loadedClass) {
        if ((method.getDeclaringClass().getName().equals(className) || method.getDeclaringClass().isAssignableFrom(loadedClass)) &&
                method.getName().equals(methodName) &&
                method.getParameterTypes().length == 2 &&
                !(method.isBridge() || method.isSynthetic()) &&
                method.getParameterTypes()[1].isAssignableFrom(Context.class)) {
            return true;
        }
        return false;
    }

    private Object mappingInputToHandlerType(Object inputParam, Class inputType) {
        if (inputType.isAssignableFrom(Number.class) || inputType.isAssignableFrom(String.class)) {
            return inputParam;
        } else if (LambdaEventSerializers.isLambdaSupportedEvent(inputType.getName())) {
            try {
                PojoSerializer serializer = LambdaEventSerializers.serializerFor(inputType, classLoader);
                String inputParamString = mapper.writeValueAsString(inputParam);
                return serializer.fromJson(inputParamString);
            } catch (JsonProcessingException e) {
                throw new RuntimeException("Error occurred while serializing lambda input type: " + e);
            }
        }
        return mapper.convertValue(inputParam, inputType);
    }
}

