'use strict'

const newrelic = require('newrelic')
require('@newrelic/aws-sdk')

let wrappedHandler

function getHandler() {
  let handler
  const { NEW_RELIC_TARGET_HANDLER, LAMBDA_TASK_ROOT = '.' } = process.env

  // console.log('%%% NEW_RELIC_TARGET_HANDLER', process.env.NEW_RELIC_TARGET_HANDLER)
  // console.log('%%% NEW_RELIC_ENABLED', process.env.NEW_RELIC_ENABLED)
  // console.log('%%% NEW_RELIC_NO_CONFIG_FILE', process.env.NEW_RELIC_NO_CONFIG_FILE)
  // console.log('%%% NEW_RELIC_APP_NAME', process.env.NEW_RELIC_APP_NAME)
  // console.log('%%% NEW_RELIC_SERVERLESS_MODE_ENABLED', process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED)
  // console.log('%%% NEW_RELIC_DISTRIBUTED_TRACING_ENABLED', process.env.NEW_RELIC_DISTRIBUTED_TRACING_ENABLED)
  // console.log('%%% NEW_RELIC_ACCOUNT_ID', process.env.NEW_RELIC_ACCOUNT_ID)
  // console.log('%%% NEW_RELIC_PRIMARY_APPLICATION_ID', process.env.NEW_RELIC_PRIMARY_APPLICATION_ID)
  // console.log('%%% NEW_RELIC_LICENSE_KEY', process.env.NEW_RELIC_LICENSE_KEY)
  // console.log('%%% NEW_RELIC_TRUSTED_ACCOUNT_KEY', process.env.NEW_RELIC_TRUSTED_ACCOUNT_KEY)
  // console.log('%%% NEW_RELIC_LOG_ENABLED', process.env.NEW_RELIC_LOG_ENABLED)
  // console.log('%%% NEW_RELIC_LOG', process.env.NEW_RELIC_LOG)

  if (!NEW_RELIC_TARGET_HANDLER) {
    throw new Error('No NEW_RELIC_TARGET_HANDLER environment variable set.')
  } else {
    handler = NEW_RELIC_TARGET_HANDLER
  }

  const parts = handler.split('.')

  if (parts.length !== 2) {
    throw new Error(
      `Improperly formatted handler environment variable: ${handler}`
    )
  }

  const [moduleToImport, handlerToWrap] = parts
  // console.log('MODULE TO IMPORT', moduleToImport)
  // console.log('handler to wrap', handlerToWrap)
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

function wrapHandler() {
  const ctx = this
  const args = Array.prototype.slice.call(arguments)
  // console.log('WRAPPING HANDLER')

  if (!wrappedHandler) {
    const userHandler = getHandler()
    wrappedHandler = newrelic.setLambdaHandler(
      (...wrapperArgs) => userHandler.apply(ctx, wrapperArgs)
    )
  }

  return wrappedHandler.apply(ctx, args)
}

module.exports.handler = wrapHandler
