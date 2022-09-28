/*
 * Copyright 2020 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict'
//
// process.env.NEW_RELIC_LAMBDA_HANDLER = 'myFunction.handler'
// process.env.NEW_RELIC_APP_NAME = 'My Test App'

const tap = require('tap')
const proxyquire = require('proxyquire')
const utils = require('@newrelic/test-utilities')

tap.test('Layer tests', (t) => {
  t.autoend()
  let handler, getHandlerPath, helper 

  t.beforeEach(() => {
    helper = utils.TestAgent.makeInstrumented() 
    const newrelic = helper.getAgentApi() 
        ;({ handler, getHandlerPath } = proxyquire('../index', {
      newrelic
    }))
  })
  t.afterEach(() => {
    helper.unload()
  })
  t.test('New Relic handler wraps customer handler', (t) => {
    const p = getHandlerPath()
    const testPath = [p.moduleToImport, p.handlerToWrap].join('.')

    t.equal(testPath, process.env.NEW_RELIC_LAMBDA_HANDLER, 'Path should be equivalent to NR Lambda Handler env var')
    t.ok(handler, 'handler should be ok')
    t.equal(typeof handler, 'function', 'handler should be a function')
    t.end()
  })

  t.test('should wrap handler in transaction', async(t) => {
    t.plan(2)
    helper.agent.on('transactionFinished', (tx) => {
      t.equal(tx.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
    })
    const res = await handler({ key: 'value'}, { functionName: 'testFn'})
    t.same(res, { statusCode: 200, body: 'response body' }, 'response should be correct')
  })
})


// test .my.file.has.many.dots.handler
