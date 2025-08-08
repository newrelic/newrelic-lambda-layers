'use strict'

// OpenTelemetry stubs - prevents runtime errors when OTEL is disabled

const noopSpan = {
  setStatus: () => {},
  setAttributes: () => {},
  addEvent: () => {},
  end: () => {},
  setAttribute: () => {},
  addEvent: () => {},
  recordException: () => {},
  setName: () => {},
  updateName: () => {}
}

const noopTracer = {
  startSpan: () => noopSpan,
  startActiveSpan: (name, options, context, fn) => {
    // Handle different argument patterns
    if (typeof options === 'function') {
      return options(noopSpan)
    } else if (typeof context === 'function') {
      return context(noopSpan)
    } else if (typeof fn === 'function') {
      return fn(noopSpan)
    }
    return noopSpan
  }
}

const noopMeter = {
  createCounter: () => ({ add: () => {} }),
  createHistogram: () => ({ record: () => {} }),
  createUpDownCounter: () => ({ add: () => {} }),
  createGauge: () => ({ record: () => {} }),
  createObservableCounter: () => ({ addCallback: () => {} }),
  createObservableGauge: () => ({ addCallback: () => {} }),
  createObservableUpDownCounter: () => ({ addCallback: () => {} })
}

const api = {
  // Trace API
  trace: {
    getTracer: () => noopTracer,
    setGlobalTracerProvider: () => {},
    getActiveSpan: () => null,
    getTracerProvider: () => ({ getTracer: () => noopTracer })
  },
  
  // Metrics API
  metrics: {
    getMeter: () => noopMeter,
    setGlobalMeterProvider: () => {},
    getMeterProvider: () => ({ getMeter: () => noopMeter })
  },
  
  // Context API
  context: {
    active: () => ({}),
    with: (ctx, fn) => fn ? fn() : undefined,
    bind: (ctx, target) => target
  },
  
  // Propagation API
  propagation: {
    inject: () => {},
    extract: () => ({}),
    createBaggage: () => ({}),
    setBaggage: () => {},
    getBaggage: () => ({})
  },
  
  // Diag API
  diag: {
    setLogger: () => {},
    debug: () => {},
    info: () => {},
    warn: () => {},
    error: () => {},
    verbose: () => {}
  }
}

// Export for different OpenTelemetry packages
module.exports = api

// Also support named exports for ES modules
module.exports.trace = api.trace
module.exports.metrics = api.metrics
module.exports.context = api.context
module.exports.propagation = api.propagation
module.exports.diag = api.diag

// Core exports
module.exports.createNoopMeter = () => noopMeter
module.exports.createNoopTracer = () => noopTracer

// Resources
module.exports.Resource = class Resource {
  constructor() {
    this.attributes = {} 
  }
  static default() {
    return new this() 
  }
  merge() {
    return this 
  }
}

// Semantic conventions (just export empty objects)
module.exports.SemanticResourceAttributes = {}
module.exports.SemanticAttributes = {}

// SDK exports
module.exports.NodeSDK = class NodeSDK {
  constructor() {}
  start() {}
  shutdown() {}
}

module.exports.MeterProvider = class MeterProvider {
  constructor() {}
  getMeter() {
    return noopMeter 
  }
  shutdown() {}
}

module.exports.TracerProvider = class TracerProvider {
  constructor() {}
  getTracer() {
    return noopTracer 
  }
  shutdown() {}
}

// Exporter stubs
module.exports.OTLPMetricExporter = class OTLPMetricExporter {
  constructor() {}
  export() {}
  shutdown() {}
}

module.exports.PeriodicExportingMetricReader = class PeriodicExportingMetricReader {
  constructor() {}
  shutdown() {}
}
