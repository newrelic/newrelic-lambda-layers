'use strict'

const tap = require('tap')
const fetch = require('node-fetch')
const BASE_URL = 'http://localhost:3000'

tap.test('CJS Handler Integration Tests', (t) => {
  t.autoend()
  
  ;[
    {
      description: 'when handler uses context.done',
      expected: 'foo',
      path: '/dev/context-done-handler',
      status: 200,
    },
    {
      description: 'when handler uses context.done which is deferred',
      expected: 'foo',
      path: '/dev/context-done-handler-deferred',
      status: 200,
    },
    {
      description: 'when handler uses context.succeed',
      expected: 'foo',
      path: '/dev/context-succeed-handler',
      status: 200,
    },
    {
      description: 'when handler uses context.succeed which is deferred',
      expected: 'foo',
      path: '/dev/context-succeed-handler-deferred',
      status: 200,
    },
    {
      description: 'when handler uses a callback',
      expected: 'foo',
      path: '/dev/callback-handler',
      status: 200,
    },
    {
      description: 'when handler uses a callback which is deferred',
      expected: 'foo',
      path: '/dev/callback-handler-deferred',
      status: 200,
    },
    {
      description: 'when handler returns a promise',
      expected: 'foo',
      path: '/dev/promise-handler',
      status: 200,
    },
    {
      description: 'when handler uses a promise which is deferred',
      expected: 'foo',
      path: '/dev/promise-handler-deferred',
      status: 200,
    },
    {
      description: 'when handler uses an async function',
      expected: 'foo',
      path: '/dev/async-function-handler',
      status: 200,
    },
    // NOTE: mix and matching of callbacks and promises is not recommended,
    // nonetheless, we test some of the behaviour to match AWS execution precedence
    {
      description:
        'when handler returns a callback but defines a callback parameter',
      expected: 'Hello Promise!',
      path: '/dev/promise-with-defined-callback-handler',
      status: 200,
    },
    {
      description:
        'when handler throws an exception in promise should return 502',
      path: '/dev/throw-exception-in-promise-handler',
      status: 502,
    },
    {
      description:
        'when handler throws an exception before calling callback should return 502',
      path: '/dev/throw-exception-in-callback-handler',
      status: 502,
    },
    {
      description:
        'when handler does not return any answer in promise should return 502',
      path: '/dev/no-answer-in-promise-handler',
      status: 502,
    },
    {
      description:
        'when handler returns bad answer in promise should return 200',
      path: '/dev/bad-answer-in-promise-handler',
      status: 200,
    },
    {
      description:
        'when handler returns bad answer in callback should return 200',
      path: '/dev/bad-answer-in-callback-handler',
      status: 200,
    },
    {
      description: 'when handler calls context.succeed and context.done',
      expected: 'Hello Context.succeed!',
      path: '/dev/context-succeed-with-context-done-handler',
      status: 200,
    },
    {
      description: 'when handler calls callback and context.done',
      expected: 'Hello Callback!',
      path: '/dev/callback-with-context-done-handler',
      status: 200,
    },
    {
      description: 'when handler calls callback and returns Promise',
      expected: 'Hello Callback!',
      path: '/dev/callback-with-promise-handler',
      status: 200,
    },
    {
      description: 'when handler calls callback inside returned Promise',
      expected: 'Hello Callback!',
      path: '/dev/callback-inside-promise-handler',
      status: 200,
    },
  ].forEach(({ description, expected, path, status }) => {
    t.test(description, async(t) => {
      const url = new URL(path, BASE_URL)

      const response = await fetch(url)
      t.equal(response.status, status, 'should have the expected status code')

      if (expected) {
        const json = await response.json()
        t.same(json, expected, 'should have the expected response')
      }

      t.end()
    })
  })
})
