'use strict'

process.env.NEW_RELIC_APP_NAME = process.env.NEW_RELIC_APP_NAME || process.env.AWS_LAMBDA_FUNCTION_NAME
process.env.NEW_RELIC_DISTRIBUTED_TRACING_ENABLED = process.env.NEW_RELIC_DISTRIBUTED_TRACING_ENABLED || 'true'
process.env.NEW_RELIC_NO_CONFIG_FILE = process.env.NEW_RELIC_NO_CONFIG_FILE || 'true'
process.env.NEW_RELIC_TRUSTED_ACCOUNT_KEY =
  process.env.NEW_RELIC_TRUSTED_ACCOUNT_KEY || process.env.NEW_RELIC_ACCOUNT_ID

if (process.env.LAMBDA_TASK_ROOT && typeof process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED !== 'undefined') {
  delete process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED
}

const newrelic = require('newrelic')

function getHandlerPath() {
  let handler
  const { NEW_RELIC_LAMBDA_HANDLER } = process.env

  if (!NEW_RELIC_LAMBDA_HANDLER) {
    throw new Error('No NEW_RELIC_LAMBDA_HANDLER environment variable set.')
  } else {
    handler = NEW_RELIC_LAMBDA_HANDLER
  }

  const parts = handler.split('.')

  if (parts.length < 2) {
    throw new Error(
      `Improperly formatted handler environment variable: ${handler}`
    )
  }

  const handlerToWrap = parts[parts.length - 1]
  const moduleToImport = handler.slice(0, handler.lastIndexOf('.'))
  return { moduleToImport, handlerToWrap }
}

function requireHandler() {
  const { LAMBDA_TASK_ROOT = '.' } = process.env
  const { moduleToImport, handlerToWrap } = getHandlerPath()
  let importedModule

  try {
    importedModule = require(`${LAMBDA_TASK_ROOT}/${moduleToImport}`)
  } catch (e) {
    if (e.code === 'MODULE_NOT_FOUND') {
      throw new Error(`Unable to import module '${moduleToImport}'`)
    }
    throw e
  }

  const userHandler = importedModule[handlerToWrap]

  if (typeof userHandler === 'undefined') {
    throw new Error(
      `Handler '${handlerToWrap}' missing on module '${moduleToImport}'`
    )
  }

  if (typeof userHandler !== 'function') {
    throw new Error(
      `Handler '${handlerToWrap}' from '${moduleToImport}' is not a function`
    )
  }

  return userHandler
}

const wrappedHandler = newrelic.setLambdaHandler(requireHandler())


function patchedHandler() {
  const args = Array.prototype.slice.call(arguments)

  return wrappedHandler.apply(this, args)
}

module.exports = { handler: patchedHandler, getHandlerPath }
