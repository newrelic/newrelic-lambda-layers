'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')
const path = require('node:path')

const handlerPath = 'test/unit/fixtures/esm/'
const earlyEndingCases = [
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

]
const handlerAndPath = [
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
]

tap.test('Early-throwing ESM Edge Cases', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  // used in validating error messages:
  let handlerFile
  let handlerMethod

  let testIndex = 0

  t.beforeEach(() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'true'
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true' // only need to check this once.

    ;({ handlerFile, handlerMethod } = earlyEndingCases[testIndex])
    if (handlerFile && handlerMethod) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
    } else if (handlerFile) {
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}`
    }
    testIndex++

    helper = utils.TestAgent.makeInstrumented()
  })

  t.afterEach(() => {
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is missing', (t) => {
    t.throws(
      () => {
        const newrelic = helper.getAgentApi()

          ;({ handler } = proxyquire('../../index', {
          'newrelic': newrelic
        }))

        return handler({key: 'this is a test'}, {functionName: handlerMethod})
      },
      'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is malformed', (t) => {
    t.throws(
      () => {
        const newrelic = helper.getAgentApi()

          ;({ handler } = proxyquire('../../index', {
          'newrelic': newrelic
        }))

        return handler({key: 'this is a test'}, {functionName: handlerMethod})
      },
      'Improperly formatted handler environment variable: test/unit/fixtures/esm/handler',
    )

    t.end()
  })


  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER throws on import', (t) => {
    t.throws(
      () => {
        const newrelic = helper.getAgentApi()
          ;({ handler } = proxyquire('../../index', {
          'newrelic': newrelic
        }))

        return handler({key: 'this is a test'}, {functionName: handlerMethod})
      },
      `Unable to import module '${handlerPath}${handlerFile}'`,
    )

    t.end()
  })
})

tap.test('ESM Edge Cases', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  // used in validating error messages:
  let handlerFile
  let handlerMethod

  let testIndex = 0

  t.beforeEach(async() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'true'
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

    const newrelic = helper.getAgentApi()

    ;({ handler } = proxyquire('../../index', {
      'newrelic': newrelic
    }))
  })

  t.afterEach(() => {
    process.env = { ...originalEnv }
    helper.unload()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER module cannot be resolved', (t) => {
    const modulePath = path.resolve('./', handlerPath)
    const extensions = ['.mjs', '.js']

    t.rejects(
      () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
      `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER does not export provided function', (t) => {
    t.rejects(
      () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
      `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER export is not a function', (t) => {
    t.rejects(
      () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
      `Handler '${handlerMethod}' from 'test/unit/fixtures/esm/errors' is not a function`,
    )

    t.end()
  })
})
