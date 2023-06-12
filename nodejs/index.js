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

function handleRequireImportError(e, moduleToImport) {
  if (e.code === 'MODULE_NOT_FOUND') {
    return new Error(`Unable to import module '${moduleToImport}'`)
  }
  return e
}

async function getImportedModule(LAMBDA_TASK_ROOT, moduleToImport) {
  const modpath = `${LAMBDA_TASK_ROOT}/${moduleToImport}`
  try {
    return require(modpath)
  } catch (e) {
    // require failed, it could be an es module, so we try to import as mjs
    if (e.code === 'MODULE_NOT_FOUND') {
      try {
        return await import(`${modpath}.mjs`)
      } catch (esmError) {
        throw handleRequireImportError(esmError, moduleToImport)
      }
    } else if (e.code === 'ERR_REQUIRE_ESM') {
      // The name is right, but we attempted to require an ECMAScript module,
      // probably one ending in `.js` but marked as ESM by `"type": "module"`
      // in package.json
      try {
        return await import(require.resolve(modpath))
      } catch (esmError) {
        throw handleRequireImportError(esmError, moduleToImport)
      }
    }
    throw handleRequireImportError(e, moduleToImport)
  }
}

async function requireHandler() {
  const { LAMBDA_TASK_ROOT = '.' } = process.env
  const { moduleToImport, handlerToWrap } = getHandlerPath()

  const userHandler = (await getImportedModule(LAMBDA_TASK_ROOT, moduleToImport))[handlerToWrap]

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

  return function (...rest) {
    const headers = rest[0]?.headers || {};

    if (headers.newrelic) {
      console.log('Applying W3C headers')
      newrelic.getTransaction().acceptDistributedTraceHeaders("HTTP", headers)
    }
    return userHandler.apply(this, rest)
  }
}

const patchedHandlerPromise = requireHandler().then(userHandler => newrelic.setLambdaHandler(userHandler))

async function patchedHandler() {
  const args = Array.prototype.slice.call(arguments)

  return patchedHandlerPromise
    .then(wrappedHandler => wrappedHandler.apply(this, args))
}

module.exports = { handler: patchedHandler, getHandlerPath }
