'use strict'

const tap = require('tap')
const proxyquire = require('proxyquire').noCallThru().noPreserveCache()
const utils = require('@newrelic/test-utilities')
const path = require('node:path')

tap.test('CJS Edge Cases', (t) => {
  const handlerPath = 'test/unit/fixtures/cjs/'
  const extensions = ['.cjs', '.js']
  let handler
  let helper
  let originalEnv
  let handlerFile
  let handlerMethod
  let modulePath

  t.beforeEach(() => {
    originalEnv = { ...process.env }
    process.env.NEW_RELIC_USE_ESM = 'false'
    process.env.LAMBDA_TASK_ROOT = './'
    process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler.handler'
  })

  t.afterEach(() => {
    process.env = { ...originalEnv }
    helper.unload()
    handler = null
    handlerFile = null
    handlerMethod = null
    modulePath = null
  })

  t.test('should delete serverless mode env var if defined', (t) => {
    t.beforeEach(() => {
      process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED = 'true'
      helper = utils.TestAgent.makeInstrumented()
      const newrelic = helper.getAgentApi()

      ;({ handler } = proxyquire('../../index', {
        'newrelic': newrelic
      }))
    })

    t.test('testing serverless mode env var', (t) => {
      t.notOk(process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED,
          'NEW_RELIC_SERVERLESS_MODE_ENABLED env var should have been deleted')
      t.end()
    })
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is missing', (t) => {
    let newrelic
    t.beforeEach(() => {
      process.env.NEW_RELIC_LAMBDA_HANDLER = undefined
      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })

    t.test('missing NEW_RELIC_LAMBDA_HANDLER test', async (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: 'testFn'})
      }
      t.throws(testInvocation(), 'No NEW_RELIC_LAMBDA_HANDLER environment variable set.')
      t.end()
    })
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER is malformed', (t) => {
    let newrelic
    t.beforeEach(() => {
      // Missing the .functionName part
      process.env.NEW_RELIC_LAMBDA_HANDLER = 'test/unit/fixtures/cjs/handler'
      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })
    t.test('testing malformed NEW_RELIC_LAMBDA_HANDLER', (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: 'testFn'})
      }

      t.throws(
          testInvocation(),
          'Improperly formatted handler environment variable: test/unit/fixtures/cjs/handler',
      )
      t.end()
    })
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER module cannot be resolved', (t) => {
    let newrelic
    t.beforeEach(() => {
      handlerFile = 'notFound'
      handlerMethod = 'noMethodFound'
      modulePath = path.resolve('./', handlerPath)
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`
      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })
    t.test('testing unresolvable handler', (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: handlerMethod })
      }

      t.throws(
         testInvocation(),
          `Unable to resolve module file at ${modulePath} with the following extensions: ${extensions.join(',')}`
      )
      t.end()
    })
    t.end()

  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER does not export provided function', (t) => {
    let newrelic
    t.beforeEach(() => {
      handlerFile = 'errors'
      handlerMethod = 'noMethodFound'
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })
    t.test('testing non-exported handler', (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: handlerMethod })
      }

      t.throws(
          testInvocation(),
          `Handler '${handlerMethod}' missing on module '${handlerPath}'`,
      )

      t.end()
    })
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER export is not a function', (t) => {
    let newrelic
    t.before(() => {
      handlerFile = 'errors'
      handlerMethod = 'notAfunction'
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })
    t.test('testing not-a-function', (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: handlerMethod })
      }
      t.throws(
          testInvocation(),
          `Handler '${handlerMethod}' from 'test/unit/fixtures/cjs/errors' is not a function`,
      )
      t.end()
    })
    t.end()
  })

  t.test('should throw when NEW_RELIC_LAMBDA_HANDLER throws on require', (t) => {
    let newrelic
    t.beforeEach(() => {
      handlerFile = 'badRequire'
      handlerMethod = 'handler'
      process.env.NEW_RELIC_LAMBDA_HANDLER = `${handlerPath}${handlerFile}.${handlerMethod}`

      helper = utils.TestAgent.makeInstrumented()
      newrelic = helper.getAgentApi()
    })
    t.test('testing throw on require', (t) => {
      const testInvocation = () => {
        ;({ handler } = proxyquire('../../index', {
              'newrelic': newrelic
            })
        )
        return handler({ key: 'this is a test'}, { functionName: handlerMethod })
      }
      t.throws(
          testInvocation(),
          `Unable to import module '${handlerPath}${handlerFile}'`,
      )
      t.end()
    })
    t.end()
  })
  t.end()
})
