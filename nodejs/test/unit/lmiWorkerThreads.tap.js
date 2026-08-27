'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')

tap.test('Layer Handler - LMI worker_threads default (CJS)', (t) => {
  t.autoend()

  t.beforeEach((t) => {
    t.context.originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler.handler'
    process.env.AWS_LAMBDA_FUNCTION_NAME = 'testFn'

    t.context.helper = utils.TestAgent.makeInstrumented()
  })

  t.afterEach((t) => {
    const { helper, originalEnv } = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('defaults NEW_RELIC_WORKER_THREADS_ENABLED to true under LMI', (t) => {
    process.env.AWS_LAMBDA_INITIALIZATION_TYPE = 'lambda-managed-instances'
    delete process.env.NEW_RELIC_WORKER_THREADS_ENABLED

    proxyquire('../../index', { newrelic: t.context.helper.getAgentApi() })

    t.equal(process.env.NEW_RELIC_WORKER_THREADS_ENABLED, 'true')
    t.end()
  })

  t.test('does not override an explicitly-set NEW_RELIC_WORKER_THREADS_ENABLED under LMI', (t) => {
    process.env.AWS_LAMBDA_INITIALIZATION_TYPE = 'lambda-managed-instances'
    process.env.NEW_RELIC_WORKER_THREADS_ENABLED = 'false'

    proxyquire('../../index', { newrelic: t.context.helper.getAgentApi() })

    t.equal(process.env.NEW_RELIC_WORKER_THREADS_ENABLED, 'false')
    t.end()
  })

  t.test('leaves NEW_RELIC_WORKER_THREADS_ENABLED untouched outside LMI', (t) => {
    delete process.env.AWS_LAMBDA_INITIALIZATION_TYPE
    delete process.env.NEW_RELIC_WORKER_THREADS_ENABLED

    proxyquire('../../index', { newrelic: t.context.helper.getAgentApi() })

    t.equal(process.env.NEW_RELIC_WORKER_THREADS_ENABLED, undefined)
    t.end()
  })
})
