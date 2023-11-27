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
]

tap.test('CJS Edge Cases', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  // used in validating error messages:
  let handlerFile
  let handlerMethod
  let testIndex = 0
  let testFn

  t.beforeEach(() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true' // only need to check this once.

    ;({ handlerFile, handlerMethod } = handlerAndPath[testIndex])
    if (handlerFile && handlerMethod) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
    } else if (handlerFile) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}`
    }
    testIndex++

    helper = utils.TestAgent.makeInstrumented()

    testFn = () => {
      const newrelic = helper.getAgentApi()

      ;({ handler } = proxyquire('../../index', {
        'newrelic': newrelic
      }))
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }
  })

  t.afterEach(() => {
    process.env = { ...originalEnv }
    helper.unload()
    testFn = null
  })

  t.test('should delete serverless mode env var if defined', async(t) => {
    const newrelic = helper.getAgentApi()

    ;({ handler } = proxyquire('../../index', {
      'newrelic': newrelic
    }))

    t.notOk(process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED,
      'NEW_RELIC_SERVERLESS_MODE_ENABLED env var should have been deleted')
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is missing', (t) => {
    t.throws(
      () => testFn(),
      'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
    )
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is malformed', (t) => {
    t.throws(
      () => testFn(),
      'Improperly formatted handler environment variable: test/unit/fixtures/cjs/handler',
    )
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER module cannot be resolved', (t) => {
    const modulePath = path.resolve('./', handlerPath)
    const extensions = ['.cjs', '.js']
    t.throws(
      () => testFn(),
      `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER does not export provided function', (t) => {
    t.throws(
      () => testFn(),
      `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER export is not a function', (t) => {
    t.throws(
        () => testFn(),
      `Handler '${handlerMethod}' from 'test/unit/fixtures/cjs/errors' is not a function`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER throws on import', (t) => {
    t.throws(
      () => testFn(),
      `Unable to import module '${handlerPath}${handlerFile}'`,
    )
    t.end()
  })
  t.end()
})
