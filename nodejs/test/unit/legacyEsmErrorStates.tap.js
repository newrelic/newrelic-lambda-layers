'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')

const handlerPath = 'test/unit/fixtures/esm/'
const testCases = [
  {
    handlerFile: 'handler',
    handlerMethod: undefined,
    type: 'throws'
  },
  {
    handlerFile: undefined,
    handlerMethod: undefined,
    type: 'throws'
  },
  {
    handlerFile: 'badImport',
    method: 'handler',
    type: 'throws'
  },
  {
    handlerFile: 'notFound',
    handlerMethod: 'noMethodFound',
    type: 'rejects'
  },
  {
    handlerFile: 'errors',
    handlerMethod: 'noMethodFound',
    type: 'rejects'
  },
  {
    handlerFile: 'errors',
    handlerMethod: 'notAfunction',
    type: 'rejects'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.contextDoneHandler',
    type: 'rejects'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.contextSucceedHandler',
    type: 'rejects'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.callbackHandler',
    type: 'rejects'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.promiseHandler',
    type: 'rejects'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.asyncFunctionHandler',
    type: 'rejects'
  }
]

tap.test('Early-throwing ESM Edge Cases', (t) => {
  t.autoend()
  t.beforeEach((t) => {
    t.context.originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'true'
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true' // only need to check this once.

    t.context.helper = utils.TestAgent.makeInstrumented()
  })

  t.afterEach((t) => {
    const { helper, originalEnv} = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  for (const test of testCases ) {
    const { handlerFile, handlerMethod, type } = test
    let testName = `should ${type} because 'NEW_RELIC_LAMBDA_HANDLER' is not an expected value for ${handlerPath}`
    if (handlerFile) {
      testName += handlerFile
    }
    if (handlerMethod) {
      testName += `.${handlerMethod}`
    }
    t.test(testName, (t) => {
      const { helper } = t.context
      if (handlerFile && handlerMethod) {
        process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
      } else if (handlerFile) {
        process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}`
      }

      t[type](
        () => {
          const newrelic = helper.getAgentApi()
          const { handler } = proxyquire('../../index', {
            'newrelic': newrelic
          })
          return handler({key: 'this is a test'}, {functionName: handlerMethod})
        },
        'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
      )

      t.end()
    })
  }
})
