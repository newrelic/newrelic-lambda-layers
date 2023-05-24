/*
 * Copyright 2020 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict'

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
      newrelic,
      'test/fixtures/esm/handler': null // necessary so that we can test what happens if require will not work
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

  t.test('should wrap handler in transaction', (t) => {
    t.plan(6)
    helper.agent.on('transactionFinished', (tx) => {
      t.equal(tx.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
    })

    handler({ key: 'value'}, { functionName: 'testFn'}, (err, response) => {
      t.notOk(err, 'response should not error')
      t.same(response, { statusCode: 200, body: 'response body value' }, 'response should match expected')
    })

    // second run is to ensure that the promise is reused and no the whole process to require the handler

    process.env = Object.assign(process.env, {
      NEW_RELIC_LAMBDA_HANDLER: 'some_not/existing_path.handler'
    })

    handler({ key: 'value second'}, { functionName: 'testFn'}, (err, response) => {
      t.notOk(err, 'second response should not error')
      t.same(response, { statusCode: 200, body: 'response body value second' }, 'second response should match expected')
    })
  })
})
