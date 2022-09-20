/*
 * Copyright 2020 New Relic Corporation. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict'
//
// process.env.NEW_RELIC_LAMBDA_HANDLER = 'myFunction.handler'
// process.env.NEW_RELIC_APP_NAME = 'My Test App'

const tap = require('tap')
const { handler, getHandlerPath } = require('../index')
const { TestAgent } = require('@newrelic/test-utilities')

tap.test('The handler wrapper wraps the handler', async (t) => {
    let helper

    t.beforeEach(t => {
        helper = new TestAgent()
    })
    t.test(async t => {
        const p = getHandlerPath()
        const testPath = [p.moduleToImport, p.handlerToWrap].join('.')

        t.ok(helper, 'Helper is ok')
        t.equal(testPath, process.env.NEW_RELIC_LAMBDA_HANDLER, 'Path should be equivalent to NR Lambda Handler env var')
        t.ok(handler, 'handler should be ok')
        t.equal(typeof handler, 'function', 'handler should be a function')
        t.end()
    })
    t.afterEach(t => {
        helper.unload()
    })
})


// test .my.file.has.many.dots.handler
