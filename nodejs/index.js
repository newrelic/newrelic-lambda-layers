'use strict'

const newrelic = require('newrelic')
require('@newrelic/aws-sdk')

let wrappedHandler

console.log('%%% in handler wrapper')

function getHandler() {
  let handler;
  console.log('%%% in getHandler')
  const { MAINLAND_TARGET_FN, IOPIPE_HANDLER, LAMBDA_TASK_ROOT = '.' } = process.env

  console.log('%%% MAINLAND_TARGET_FN', MAINLAND_TARGET_FN)
  console.log('%%% IOPIPE_HANDLER', IOPIPE_HANDLER)

  if (!MAINLAND_TARGET_FN) {
    console.error('no MAINLAND_TARGET_FN defined');
    throw new Error('No MAINLAND_TARGET_FN environment variable set.')
  } else {
    handler = MAINLAND_TARGET_FN;
  }
  if (!IOPIPE_HANDLER) {
    console.warn('no IOPIPE_HANDLER defined');
  }

  // if (!_HANDLER) {
  //   console.error('%%% no _HANDLER defined');
  // } else {
  //   console.log('%%% defining _HANDLER', _HANDLER)
  //   handler = _HANDLER;
  // }

  if (!handler) {
    console.log('%%% not sure which handler to use')
    throw new Error('No handler environment variable set.')
  }

  const parts = handler.split('.')

  if (parts.length !== 2) {
    console.error('%%% malformed handler', parts)
    throw new Error(
      `Improperly formatted handler environment variable: ${handler}`
    )
  }

  const [moduleToImport, handlerToWrap] = parts

  let importedModule
  console.log('%%% module to import!', `${LAMBDA_TASK_ROOT}/${moduleToImport}`)
  console.log('%%% handler to wrap!', `${handler}`)

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
  console.log('%%% userhandler', !!userHandler)

  return userHandler
}

function wrapHandler() {
  console.log('%%% in wrapHandler')

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
