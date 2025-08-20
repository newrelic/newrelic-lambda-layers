'use strict'

// Comprehensive stub implementation for OpenTelemetry packages
// Provides noop implementations for all commonly used OTEL APIs

const noop = () => {}
const noopReturnsPromise = () => Promise.resolve()
const noopReturnsThis = function noopReturnsThis() {
  return this
}
const noopReturnsObj = () => ({})

// Create noop span that implements common span interface
const createNoopSpan = () => ({
  end: noop,
  setStatus: noopReturnsThis,
  setAttributes: noopReturnsThis,
  setAttribute: noopReturnsThis,
  addEvent: noopReturnsThis,
  updateName: noopReturnsThis,
  isRecording: () => false,
  recordException: noop,
  spanContext: () => ({
    traceId: '00000000000000000000000000000000',
    spanId: '0000000000000000',
    traceFlags: 0,
    isRemote: false
  })
})

// Create noop tracer
const createNoopTracer = () => ({
  startSpan: createNoopSpan,
  startActiveSpan: (name, optionsOrFn, contextOrFn, fn) => {
    const span = createNoopSpan()
    const callback = typeof optionsOrFn === 'function' ? optionsOrFn :
      typeof contextOrFn === 'function' ? contextOrFn : fn
    if (callback) return callback(span)
    return span
  }
})

// Create noop meter
const createNoopMeter = () => ({
  createCounter: () => ({ add: noop, bind: noopReturnsObj }),
  createUpDownCounter: () => ({ add: noop, bind: noopReturnsObj }),
  createHistogram: () => ({ record: noop, bind: noopReturnsObj }),
  createObservableCounter: () => ({ addCallback: noop }),
  createObservableUpDownCounter: () => ({ addCallback: noop }),
  createObservableGauge: () => ({ addCallback: noop })
})

// Create noop logger
const createNoopLogger = () => ({
  emit: noop
})

// Comprehensive exports object covering all OTEL packages
const stubExports = {
  // Core API exports (from @opentelemetry/api)
  trace: {
    setGlobalTracerProvider: noop,
    getGlobalTracerProvider: () => ({ getTracer: createNoopTracer }),
    setGlobalTracer: noop,
    getGlobalTracer: createNoopTracer,
    disable: noop
  },
  context: {
    setGlobalContextManager: noop,
    getGlobalContextManager: () => ({
      active: () => ({}),
      with: (context, fn) => fn(),
      bind: (context, target) => target,
      enable: () => this,
      disable: () => this
    }),
    active: () => ({}),
    disable: noop
  },
  propagation: {
    setGlobalPropagator: noop,
    getGlobalPropagator: () => ({
      inject: noop,
      extract: (context) => context || {},
      fields: () => []
    }),
    disable: noop
  },
  diag: {
    setLogger: noop,
    getLogger: () => ({ debug: noop, info: noop, warn: noop, error: noop }),
    disable: noop
  },
  metrics: {
    setGlobalMeterProvider: noop,
    getMeterProvider: () => ({ getMeter: createNoopMeter }),
    disable: noop
  },
  
  // Logs API exports (from @opentelemetry/api-logs)
  logs: {
    setGlobalLoggerProvider: noop,
    getLoggerProvider: () => ({ getLogger: createNoopLogger }),
    disable: noop
  },
  
  // SDK exports (from @opentelemetry/sdk-trace-base)
  BasicTracerProvider: function BasicTracerProvider() {
    return {
      register: noop,
      getTracer: createNoopTracer,
      shutdown: noopReturnsPromise,
      forceFlush: noopReturnsPromise,
      addSpanProcessor: noop,
      getActiveSpanProcessor: () => ({ onStart: noop, onEnd: noop, shutdown: noopReturnsPromise })
    }
  },
  
  // Resources (from @opentelemetry/resources)
  Resource: {
    default: () => ({ attributes: {}, merge: noopReturnsThis }),
    empty: () => ({ attributes: {}, merge: noopReturnsThis }),
    EMPTY: { attributes: {}, merge: noopReturnsThis }
  },
  
  // Semantic conventions (from @opentelemetry/semantic-conventions)
  SemanticResourceAttributes: {},
  SemanticAttributes: {},
  
  // Core utilities (from @opentelemetry/core)
  suppressTracing: noop,
  unsuppressTracing: noop,
  
  // Factory functions
  createNoopMeter,
  createNoopTracer,
  
  // Enums and constants
  SpanKind: { INTERNAL: 0, CLIENT: 1, SERVER: 2, PRODUCER: 3, CONSUMER: 4 },
  SpanStatusCode: { UNSET: 0, OK: 1, ERROR: 2 },
  TraceFlags: { NONE: 0, SAMPLED: 1 },
  SamplingDecision: { NOT_RECORD: 0, RECORD: 1, RECORD_AND_SAMPLED: 2 },
  ValueType: { INT: 0, DOUBLE: 1 },
  DiagLogLevel: { NONE: 0, ERROR: 30, WARN: 50, INFO: 60, DEBUG: 70, VERBOSE: 80, ALL: 9999 },
  
  // Default export
  default: {}
}

// Export everything
module.exports = stubExports
Object.assign(exports, stubExports)
