'use strict'

process.env.NEW_RELIC_NO_CONFIG_FILE = process.env.NEW_RELIC_NO_CONFIG_FILE || 'true'
process.env.NEW_RELIC_LOG_ENABLED = process.env.NEW_RELIC_LOG_ENABLED || 'true'
process.env.NEW_RELIC_LOG = process.env.NEW_RELIC_LOG || 'stdout'
process.env.NEW_RELIC_LOG_LEVEL = process.env.NEW_RELIC_LOG_LEVEL || 'info'

const newrelic = require('newrelic')
require('@newrelic/aws-sdk')

let wrappedHandler

function getHandler() {
  let handler
  const { NEW_RELIC_LAMBDA_HANDLER, LAMBDA_TASK_ROOT = '.' } = process.env

  if (!NEW_RELIC_LAMBDA_HANDLER) {
    throw new Error('No NEW_RELIC_LAMBDA_HANDLER environment variable set.')
  } else {
    handler = NEW_RELIC_LAMBDA_HANDLER
  }

  const parts = handler.split('.')

  if (parts.length !== 2) {
    throw new Error(
      `Improperly formatted handler environment variable: ${handler}`
    )
  }

  const [moduleToImport, handlerToWrap] = parts

  let importedModule

  try {
    /* eslint-disable import/no-dynamic-require*/
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

function patchIO(method) {
  const warning = `
    Use of context.iopipe.* (including ${method}) is no longer supported. 
    Please see New Relic Node agent documentation here: 
    https://docs.newrelic.com/docs/agents/nodejs-agent
    `
  /* eslint-disable no-console */
  console.warn(warning)
}

const iopipePatch = {
  label: () => patchIO('label'),
  mark: {
    start: () => patchIO('mark.start'),
    end: () => patchIO('mark.end')
  },
  measure: () => patchIO('measure'),
  metric: () => patchIO('metric')
}

function wrapHandler() {
  const ctx = this
  const args = Array.prototype.slice.call(arguments)

  if (!wrappedHandler) {
    if (process.env.IOPIPE_TOKEN && args[1] && typeof args[1] === 'object') {
      args[1].iopipe = iopipePatch
    }
    const userHandler = getHandler()
    wrappedHandler = newrelic.setLambdaHandler(
      (...wrapperArgs) => userHandler.apply(ctx, wrapperArgs)
    )
  }

  return wrappedHandler.apply(ctx, args)
}

module.exports.handler = wrapHandler
