'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')
const path = require('node:path')

const handlerPath = 'test/unit/fixtures/cjs/'
const handlerAndPath = [
  {
    handlerFile: 'handler',
    handlerMethod: 'handler'
  },
  {
    handlerFile: undefined,
    handlerMethod: undefined
  },
  {
    handlerFile: 'handler',
    handlerMethod: undefined
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
    handlerFile: 'badImport',
    method: 'handler'
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

tap.test('CJS Edge Cases', (t) => {
  t.autoend()
  let testIndex = 0
  t.beforeEach((t) => {
    t.context.originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true' // only need to check this once.

    const { handlerFile, handlerMethod } = handlerAndPath[testIndex]
    if (handlerFile && handlerMethod) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
    } else if (handlerFile) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}`
    }
    testIndex++

    const helper = utils.TestAgent.makeInstrumented()

    // Some loading-related errors happen early; to test these, we have to wrap
    // in the test assertion, so we can compare the surfaced error to what we expect.
    t.context.testFn = () => {
      const newrelic = helper.getAgentApi()

      const { handler } = proxyquire('../../index', {
        'newrelic': newrelic
      })
      t.context.handler = handler
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }
    t.context.handlerFile = handlerFile
    t.context.handlerMethod = handlerMethod
    t.context.helper = helper
  })

  t.afterEach((t) => {
    const { originalEnv, helper } = t.context
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should delete serverless mode env var if defined', (t) => {
    const { helper } = t.context
    const newrelic = helper.getAgentApi()

    proxyquire('../../index', {
      'newrelic': newrelic
    })

    t.notOk(process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED,
      'NEW_RELIC_SERVERLESS_MODE_ENABLED env var should have been deleted')
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is missing', (t) => {
    const { testFn } = t.context
    t.throws(
      () => testFn(),
      'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
    )
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is malformed', (t) => {
    const { testFn } = t.context
    t.throws(
      () => testFn(),
      'Improperly formatted handler environment variable: test/unit/fixtures/cjs/handler',
    )
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER module cannot be resolved', (t) => {
    const { testFn } = t.context
    const modulePath = path.resolve('./', handlerPath)
    const extensions = ['.cjs', '.js']
    t.throws(
      () => testFn(),
      `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER does not export provided function', (t) => {
    const { handlerMethod, testFn } = t.context
    t.throws(
      () => testFn(),
      `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER export is not a function', (t) => {
    const { handlerMethod, testFn } = t.context
    t.throws(
      () => testFn(),
      `Handler '${handlerMethod}' from 'test/unit/fixtures/cjs/errors' is not a function`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER throws on import', (t) => {
    const { handlerFile, testFn } = t.context
    t.throws(
      () => testFn(),
      `Unable to import module '${handlerPath}${handlerFile}'`,
    )
    t.end()
  })
  t.end()
})
