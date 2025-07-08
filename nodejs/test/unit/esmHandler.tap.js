'use strict'

const tap = require('tap')
const utils = require('@newrelic/test-utilities')
const td = require('testdouble')

tap.test('Layer Handler - ESM Function', (t) => {
  t.autoend()

  t.beforeEach(async(t) => {
    const originalEnv = { ...process.env }
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/esm/handler.handler'
    process.env.AWS_LAMBDA_FUNCTION_NAME = 'testFn'

    const helper = utils.TestAgent.makeInstrumented()

    const newrelic = helper.getAgentApi()
    await td.replaceEsm('newrelic', {}, newrelic)
    const { handler } =  await import('../../esm.mjs')
    t.context.helper = helper
    t.context.handler = handler
    t.context.originalEnv = originalEnv
  })

  t.afterEach((t) => {
    const { helper, originalEnv } = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should wrap handler in transaction', async(t) => {
    const { helper, handler } = t.context
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
})
