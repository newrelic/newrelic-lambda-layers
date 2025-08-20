// Stub TypeScript definitions for OpenTelemetry packages
// Provides basic type definitions to prevent TypeScript errors

export * from './stub-types';

// Core API types
export declare const trace: {
  setGlobalTracerProvider(provider: any): void;
  getGlobalTracerProvider(): any;
  setGlobalTracer(tracer: any): void;
  getGlobalTracer(): any;
  disable(): void;
};

export declare const context: {
  setGlobalContextManager(manager: any): void;
  getGlobalContextManager(): any;
  active(): any;
  disable(): void;
};

export declare const propagation: {
  setGlobalPropagator(propagator: any): void;
  getGlobalPropagator(): any;
  disable(): void;
};

export declare const diag: {
  setLogger(logger: any): void;
  getLogger(): any;
  disable(): void;
};

export declare const metrics: {
  setGlobalMeterProvider(provider: any): void;
  getMeterProvider(): any;
  disable(): void;
};

export declare const logs: {
  setGlobalLoggerProvider(provider: any): void;
  getLoggerProvider(): any;
  disable(): void;
};

// Resource types
export declare const Resource: {
  default(): any;
  empty(): any;
  EMPTY: any;
};

// Semantic conventions
export declare const SemanticResourceAttributes: any;
export declare const SemanticAttributes: any;

// Enums
export declare const SpanKind: {
  INTERNAL: number;
  CLIENT: number;
  SERVER: number;
  PRODUCER: number;
  CONSUMER: number;
};

export declare const SpanStatusCode: {
  UNSET: number;
  OK: number;
  ERROR: number;
};

export declare const TraceFlags: {
  NONE: number;
  SAMPLED: number;
};

export declare const SamplingDecision: {
  NOT_RECORD: number;
  RECORD: number;
  RECORD_AND_SAMPLED: number;
};

export declare const ValueType: {
  INT: number;
  DOUBLE: number;
};

export declare const DiagLogLevel: {
  NONE: number;
  ERROR: number;
  WARN: number;
  INFO: number;
  DEBUG: number;
  VERBOSE: number;
  ALL: number;
};

// Factory functions
export declare function createNoopMeter(): any;
export declare function createNoopTracer(): any;

// SDK classes
export declare class BasicTracerProvider {
  constructor(...args: any[]);
  register(): void;
  getTracer(): any;
  shutdown(): Promise<void>;
  forceFlush(): Promise<void>;
  addSpanProcessor(processor: any): void;
  getActiveSpanProcessor(): any;
}
