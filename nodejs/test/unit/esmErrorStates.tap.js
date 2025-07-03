'use strict'

const tap = require('tap')
const utils = require('@newrelic/test-utilities')
const td = require('testdouble')

const handlerPath = 'test/unit/fixtures/esm/'
const testCases = [
  {
    handlerFile: 'handler',
    handlerMethod: undefined
  },
  {
    handlerFile: undefined,
    handlerMethod: undefined
  },
  {
    handlerFile: 'badImport',
    method: 'handler'
  },
  {
    handlerFile: 'notFound',
    handlerMethod: 'noMethodFound'
  },
  {
    handlerFile: 'errors',
    handlerMethod: 'noMethodFound'
  },
  {
    handlerFile: 'errors',
    handlerMethod: 'notAfunction'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.contextDoneHandler'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.contextSucceedHandler'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.callbackHandler'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.promiseHandler'
  },
  {
    handlerFile: 'nestedHandler',
    handlerMethod: 'nested.asyncFunctionHandler'
  }
]

tap.test('Early-throwing ESM Edge Cases', (t) => {
  t.autoend()

  t.beforeEach(async(t) => {
    t.context.originalEnv = { ...process.env }
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true' // only need to check this once.

    const helper = utils.TestAgent.makeInstrumented()
    const newrelic = helper.getAgentApi()
    await td.replaceEsm('newrelic', {}, newrelic)

    t.context.helper = helper
  })

  t.afterEach((t) => {
    const { helper, originalEnv } = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  for (const test of testCases ) {
    const { handlerFile, handlerMethod } = test
    let testName = `should reject because 'NEW_RELIC_LAMBDA_HANDLER' is not an expected value for ${handlerPath}`
    if (handlerFile) {
      testName += handlerFile
    }
    if (handlerMethod) {
      testName += `.${handlerMethod}`
    }

    t.test(testName, (t) => {
      if (handlerFile && handlerMethod) {
        process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
      } else if (handlerFile) {
        process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}`
      }
      t.rejects(
        async() => {
          const { handler } =  await import('../../esm.mjs')
          return handler({key: 'this is a test'}, {functionName: handlerMethod})
        },
        'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
      )

      t.end()
    })
  }
})
