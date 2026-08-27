'use strict'

const tap = require('tap')
const utils = require('@newrelic/test-utilities')
const td = require('testdouble')

tap.test('Layer Handler - LMI worker_threads default (ESM)', (t) => {
  t.autoend()

  t.test('defaults NEW_RELIC_WORKER_THREADS_ENABLED to true under LMI', async(t) => {
    const originalEnv = { ...process.env }
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/esm/handler.handler'
    process.env.AWS_LAMBDA_FUNCTION_NAME = 'testFn'
    process.env.AWS_LAMBDA_INITIALIZATION_TYPE = 'lambda-managed-instances'
    delete process.env.NEW_RELIC_WORKER_THREADS_ENABLED

    const helper = utils.TestAgent.makeInstrumented()
    await td.replaceEsm('newrelic', {}, helper.getAgentApi())

    await import('../../esm.mjs')

    t.equal(process.env.NEW_RELIC_WORKER_THREADS_ENABLED, 'true')

    process.env = { ...originalEnv }
    helper.unload()
    t.end()
  })
})
