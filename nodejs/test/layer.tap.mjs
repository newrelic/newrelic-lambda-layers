/*
 * Copyright 2020 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict'

import tap from 'tap'
import * as td from 'testdouble'
import * as utils from '@newrelic/test-utilities'

tap.test('Layer tests', (t) => {
  t.autoend()
  let handler, getHandlerPath, helper, fakeAgent

  t.beforeEach(async () => {
    helper = utils.TestAgent.makeInstrumented()
    fakeAgent = helper.getAgentApi()
    // await td.replace('newrelic', fakeAgent); // doesn't replace nr
    const replaced = await (await td.replaceEsm('newrelic', {},  fakeAgent));  // Looks weird and wrong
        // How to apply the replaced newrelic to this imported file under test?
        // It's still referencing the real, unmocked NR agent.
        ({handler, getHandlerPath} = await import('../index.js'));
  })
  t.afterEach(() => {
    td.reset()
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
    t.plan(4)
    helper.agent.on('transactionFinished', (tx) => {
      t.equal(tx.name, 'OtherTransaction/Function/testFn', 'transaction should be properly named')
    })

    const res = await handler({ key: 'value'}, { functionName: 'testFn'})

    t.same(res, { statusCode: 200, body: 'response body value' }, 'response should be correct')
    // second run is to ensure that the promise is reused and no the whole process to require the handler

    process.env = Object.assign(process.env, {
      NEW_RELIC_LAMBDA_HANDLER: 'some_not/existing_path.handler'
    })

    const resSecond = await handler({ key: 'value second'}, { functionName: 'testFn'})

    t.same(resSecond, { statusCode: 200, body: 'response body value second' }, 'response should be correct')
  })
})
