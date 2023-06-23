'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')
const path = require('node:path')

tap.test('Edge cases (CJS)', (t) => {
  t.autoend()
  let handler
  let helper
  let originalEnv

  t.beforeEach(() => {
    originalEnv = {...process.env}
    process.env.NEW_RELIC_USE_ESM = 'false'

    helper = utils.TestAgent.makeInstrumented()

    const newrelic = helper.getAgentApi()

    ;({ handler } = proxyquire('../../index', {
      'newrelic': newrelic
    }))
  })

  t.afterEach(() => {
    process.env = {...originalEnv}
    helper.unload()
  })

  t.test('should delete serverless mode env var if defined', (t) => {
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

  t.test('should throw', async(t) => {
    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: 'testFn'})
    }, 'No NEW_RELIC_LAMBDA_HANDLER environment variable set.',
    'when NEW_RELIC_LAMBDA_HANDLER is unset')

    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler'
    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: 'testFn'})
    }, `Improperly formatted handler environment variable: test/unit/fixtures/cjs/handler`,
    'when NEW_RELIC_LAMBDA_HANDLER is not defined as {path}.{function}')

    let handlerPath = 'test/unit/fixtures/'
    let handlerFile = 'notFound'
    let handlerMethod = 'noMethodFound'
    let modulePath = path.resolve('./', handlerPath)
    const extensions = ['.cjs', '.js']
    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }, `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`,
    `when module file can't be found`)

    handlerFile = 'errors'
    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }, `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
    `when file is found, but handler function is not found`)

    handlerMethod = 'notAfunction'
    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }, `Handler '${handlerMethod}' from 'test/unit/fixtures/errors' is not a function`,
    `when NEW_RELIC_LAMBDA_HANDLER is not a function`)

    handlerFile = 'badRequire'
    handlerMethod = 'handler'
    process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
    t.throws(() => {
      return handler({ key: 'this is a test'}, { functionName: handlerMethod })
    }, `Unable to import module '${handlerPath}${handlerFile}'`,
    `when handler file can't load dependencies`)

    t.end()
  })
})
