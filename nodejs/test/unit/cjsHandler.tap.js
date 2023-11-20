'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')

tap.test('Layer Handler - CJS Function', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  t.beforeEach(() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler.handler'
    process.env.AWS_LAMBDA_FUNCTION_NAME = 'testFn'

    helper = utils.TestAgent.makeInstrumented()

    const newrelic = helper.getAgentApi()

    ;({ handler } = proxyquire('../../index', {
      'newrelic': newrelic
    }))
  })

  t.afterEach(() => {
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should wrap handler in transaction', async(t) => {
    helper.agent.on('transactionFinished', (transaction) => {
      t.equal(transaction.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
    })

    t.equal(typeof handler, 'function', 'handler should be a function')
    const res = await handler({ key: 'this is a test'}, { functionName: 'testFn'})
    t.same(res, { statusCode: 200, body: 'response body this is a test' }, 'response should be correct')
    t.end()
  })
})
