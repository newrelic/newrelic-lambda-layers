'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')

tap.test('Layer Handler - CJS Function', (t) => {
  t.autoend()

  t.beforeEach((t) => {
    t.context.originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler.handler'
    process.env.AWS_LAMBDA_FUNCTION_NAME = 'testFn'

    const helper = utils.TestAgent.makeInstrumented()

    const newrelic = helper.getAgentApi()

    const { handler } = proxyquire('../../index', {
      'newrelic': newrelic
    })
    t.context.helper = helper
    t.context.handler = handler
    t.context.newrelic = newrelic
  })

  t.afterEach((t) => {
    const { helper, originalEnv } = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should wrap handler in transaction', async(t) => {
    const { handler, helper } = t.context
    const promise = new Promise((resolve) => {
      helper.agent.on('transactionFinished', (transaction) => {
        t.equal(transaction.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
        resolve()
      })
    })

    t.equal(typeof handler, 'function', 'handler should be a function')
    // TODO: Once we release agent this will work
    // t.equal(handler[Symbol.for('test.symbol')], 'value', 'should have symbol on wrapped handler')
    const res = await handler({ key: 'this is a test'}, { functionName: 'testFn'})
    t.same(res, { statusCode: 200, body: 'response body this is a test' }, 'response should be correct')
    await promise
  })

  t.test('should wrap nested asyncFunctionHandler in transaction', async(t) => {
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler.nested.asyncFunctionHandler'

    const { handler } = proxyquire('../../index', {
      'newrelic': t.context.newrelic
    })
    t.context.handler = handler

    const promise = new Promise((resolve) => {
      t.context.helper.agent.on('transactionFinished', (transaction) => {
        t.equal(transaction.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
        resolve()
      })
    })

    t.equal(typeof handler, 'function', 'handler should be a function')
    const res = await handler({ key: 'this is a test'}, { functionName: 'testFn'})
    t.same(res, { statusCode: 200, body: JSON.stringify('foo') }, 'response should be correct')
    await promise
  })
})
