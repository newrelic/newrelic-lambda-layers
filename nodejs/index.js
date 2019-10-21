'use strict'

const newrelic = require('newrelic')
require('@newrelic/aws-sdk')

let wrappedHandler

function getHandler() {
  let handler;
  const { MAINLAND_TARGET_FN, IOPIPE_HANDLER, LAMBDA_TASK_ROOT = '.' } = process.env

  if (!MAINLAND_TARGET_FN) {
    throw new Error('No MAINLAND_TARGET_FN environment variable set.')
  } else {
    handler = MAINLAND_TARGET_FN;
  }
  if (IOPIPE_HANDLER) {
    console.warn('IOPIPE_HANDLER defined; patching.');

  }

  if (!handler) {
    throw new Error('No handler environment variable set.')
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

function wrapHandler() {
  const ctx = this
  const args = Array.prototype.slice.call(arguments)

  if (!wrappedHandler) {
    const userHandler = getHandler()
    console.log('*** setting wrapped handler')
    wrappedHandler = newrelic.setLambdaHandler(
      (...wrapperArgs) => userHandler.apply(ctx, wrapperArgs)
    )
  }

  return wrappedHandler.apply(ctx, args)
}

module.exports.wrapper = wrapHandler
