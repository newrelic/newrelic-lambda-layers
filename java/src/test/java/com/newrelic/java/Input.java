package com.newrelic.java;

public class Input {

    public static Input create(String message) {
        Input input = new Input();
        input.setMessage(message);
        return input;
    }

    private String message;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
