'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')
const path = require('node:path')

tap.test('CJS Edge Cases', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  t.beforeEach(() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'

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

  t.test('should delete serverless mode env var if defined', async(t) => {
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true'

    // redundant, but needed for this test
    const newrelic = helper.getAgentApi()

    ;({ handler } = proxyquire('../../index', {
      'newrelic': newrelic
    }))

    t.notOk(process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED,
        'NEW_RELIC_SERVERLESS_MODE_ENABLED env var should have been deleted')
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is missing', (t) => {
    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: 'testFn'}),
        'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is malformed', async(t) => {
    // Missing the .functionName part
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler'

    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: 'testFn'}),
        'Improperly formatted handler environment variable: test/unit/fixtures/cjs/handler',
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER module cannot be resolved', async(t) => {
    const handlerPath = 'test/unit/fixtures/cjs/'
    const handlerFile = 'notFound'
    const handlerMethod = 'noMethodFound'
    const modulePath = path.resolve('./', handlerPath)
    const extensions = ['.cjs', '.js']
    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
        `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER does not export provided function', async(t) => {
    const handlerPath = 'test/unit/fixtures/cjs/'
    const handlerFile = 'errors'
    const handlerMethod = 'noMethodFound'

    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
        `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER export is not a function', async(t) => {
    const handlerPath = 'test/unit/fixtures/cjs/'
    const handlerFile = 'errors'
    const handlerMethod = 'notAfunction'

    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
        `Handler '${handlerMethod}' from 'test/unit/fixtures/cjs/errors' is not a function`,
    )

    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER throws on import', async(t) => {
    const handlerPath = 'test/unit/fixtures/cjs/'
    const handlerFile = 'badImport'
    const handlerMethod = 'handler'

    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.rejects(
        () => handler({ key: 'this is a test'}, { functionName: handlerMethod }),
        `Unable to import module '${handlerPath}${handlerFile}'`,
    )

    t.end()
  })
  t.end()
})
