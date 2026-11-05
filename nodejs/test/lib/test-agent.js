'use strict'

/*
 * Local replacement for @newrelic/test-utilities' TestAgent.
 * Builds directly on the `newrelic` package (already a production
 * dependency), reproducing only what this repo's tests use:
 * makeInstrumented, getAgentApi, agent, unload.
 */

const Agent = require('newrelic/lib/agent')
const API = require('newrelic/api')
const configurator = require('newrelic/lib/config')
const InstrumentationTracker = require('newrelic/lib/instrumentation-tracker')
const shimmer = require('newrelic/lib/shimmer')

function removeListenerByName(emitter, event, name) {
  for (const listener of emitter.listeners(event)) {
    if (listener instanceof Function && listener.name === name) {
      emitter.removeListener(event, listener)
    }
  }
}

class TestAgent {
  constructor(conf, setState = true) {
    const config = configurator.createInstance(conf)
    config.debug = config.debug || {}
    config.debug.double_linked_transactions = true
    config.applications = () => ['newrelic-lambda-layers tests']

    this.agent = new Agent(config)

    if (setState) {
      this.agent.setState('started')
    }
  }

  static makeInstrumented(conf, setState) {
    const helper = new TestAgent(conf, setState)
    helper.instrument()
    return helper
  }

  instrument() {
    shimmer.debug = true
    shimmer.registerCoreInstrumentation(this.agent)
    shimmer.registerHooks(this.agent)
    return this
  }

  unload() {
    shimmer.removeHooks()
    shimmer.unwrapAll()
    shimmer.debug = false
    shimmer.registeredInstrumentations = new InstrumentationTracker()

    removeListenerByName(process, 'uncaughtException', '__NR_uncaughtExceptionHandler')
    removeListenerByName(process, 'unhandledRejection', '__NR_unhandledRejectionHandler')
  }

  getAgentApi() {
    if (!this._agentApi) {
      this._agentApi = new API(this.agent)
    }
    return this._agentApi
  }
}

module.exports = { TestAgent }
