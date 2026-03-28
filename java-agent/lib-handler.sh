#!/bin/bash

set -ef -o pipefail

function log_debug {
  if [[ "$NEW_RELIC_EXTENSION_LOG_LEVEL" == "DEBUG" ]]; then 
    echo "[NR_JAVA_HANDLER] DEBUG $1"
  fi
}

function log {
  echo "[NR_JAVA_HANDLER] $1"
}

function setup_agent {
    log "Begin detecting java version"
    if type -p java; then
    log found java executable in PATH
    _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    log found java executable in JAVA_HOME     
    _java="$JAVA_HOME/bin/java"
    else
    log "No java version detected"
    fi

    if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    log "Verifying JVM version is compatable. Only JVMs versions 17 and up are supported."
    log "Java version $version detected"
    if [[ "$version" > "17" ]] || [[ "$version" == "17" ]]; then
        export JAVA_TOOL_OPTIONS="-javaagent:/opt/newrelic/newrelic.jar ${JAVA_TOOL_OPTIONS}"
        log "Attatched New Relic Java Agent"
    else         
        log version is less than 17, will not attatch the New Relic Java Agent
    fi
    else
        export JAVA_TOOL_OPTIONS="-javaagent:/opt/newrelic/newrelic.jar ${JAVA_TOOL_OPTIONS}"
        log "Attatched New Relic Java Agent"
    fi

    ########################################

    if [ -z "${NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED}" ]; then
      export NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED=false
      log_debug "Setting NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED to be false"
    fi

    if [ -z "${NEW_RELIC_CROSS_APPLICATION_TRACER_ENABLED}" ]; then
      export NEW_RELIC_CROSS_APPLICATION_TRACER_ENABLED=false
      log_debug "Setting NEW_RELIC_CROSS_APPLICATION_TRACER_ENABLED to be false"
    fi

    if [ -z "${NEW_RELIC_SPAN_EVENTS_COLLECT_SPAN_EVENTS}" ]; then
      export NEW_RELIC_SPAN_EVENTS_COLLECT_SPAN_EVENTS=true
      log_debug "Setting NEW_RELIC_SPAN_EVENTS_COLLECT_SPAN_EVENTS to be true"
    fi

    if [ -z "${NEW_RELIC_TRANSACTION_TRACER_COLLECT_TRACES}" ]; then
      export NEW_RELIC_TRANSACTION_TRACER_COLLECT_TRACES=true
      log_debug "Setting NEW_RELIC_TRANSACTION_TRACER_COLLECT_TRACES to be true"
    fi

    if [ -z "${NEW_RELIC_APP_NAME}" ]; then
      export NEW_RELIC_APP_NAME=lambda-function
      log_debug "Setting NEW_RELIC_APP_NAME to be lambda-function"
    fi

    if [ -z "${NEW_RELIC_LOG_FILE_PATH}" ]; then
      mkdir -p /tmp/logs
      export NEW_RELIC_LOG_FILE_PATH=/tmp/logs/
      log_debug "Setting NEW_RELIC_LOG_FILE_PATH to be /tmp/logs/"
    fi

    export NEW_RELIC_SERVERLESS_MODE_ENABLED=true
    log_debug "Always setting NEW_RELIC_SERVERLESS_MODE_ENABLED to be true"

    export NEW_RELIC_ENABLE_AUTO_APP_NAMING=false
    log_debug "Always setting NEW_RELIC_ENABLE_AUTO_APP_NAMING to be false"
}