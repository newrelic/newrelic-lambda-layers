'use strict'

process.env.NEW_RELIC_APP_NAME = process.env.NEW_RELIC_APP_NAME || process.env.AWS_LAMBDA_FUNCTION_NAME
process.env.NEW_RELIC_DISTRIBUTED_TRACING_ENABLED = process.env.NEW_RELIC_DISTRIBUTED_TRACING_ENABLED || 'true'
process.env.NEW_RELIC_NO_CONFIG_FILE = process.env.NEW_RELIC_NO_CONFIG_FILE || 'true'
process.env.NEW_RELIC_TRUSTED_ACCOUNT_KEY = process.env.NEW_RELIC_TRUSTED_ACCOUNT_KEY || process.env.NEW_RELIC_ACCOUNT_ID

if (process.env.LAMBDA_TASK_ROOT && typeof process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED !== 'undefined') {
  delete process.env.NEW_RELIC_SERVERLESS_MODE_ENABLED
}

const newrelic = require('newrelic')
require('@newrelic/aws-sdk')


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

const wrappedHandler = newrelic.setLambdaHandler(getHandler())

const ioMarks = {}

function patchIO(method, payload) {
  const warning = `
    Use of context.iopipe.* (including ${method}) is no longer supported. 
    Please see New Relic Node agent documentation here: 
    https://docs.newrelic.com/docs/agents/nodejs-agent
    `

  let property, value

  if (method === 'label') {
    property = `customLabel.${payload.value}`
    value = payload.value
  } else if (method === 'metric') {
    property = `customMetric.${payload.name}`
    value = payload.value
  } else if (method === 'measure' && payload.name && ioMarks[payload.end].end && ioMarks[payload.start].start) {
    property = `customMetric.${payload.name}`
    value = ioMarks[payload.end].end - ioMarks[payload.start].start
  }

  if (typeof property !== 'undefined' && typeof value !== 'undefined') {
    newrelic.addCustomAttribute(property, value)
  }
  /* eslint-disable no-console */
  console.warn(warning)
}

const wrapPatch = () => {
  return {
    label: labelName => patchIO('label', {value: labelName}),
    mark: {
      start: markName => {
        ioMarks[markName] = {start: new Date().getTime()}
        return ioMarks[markName]
      },
      end: markName => {
        ioMarks[markName] = {end: new Date().getTime()}
        patchIO('measure', {name: markName, start: markName, end: markName})
      }
    },
    measure: (name, start, end) => {
      patchIO('measure', {name, start, end})
    },
    metric: (name, value) => patchIO('metric', {name, value})
  }
}

function patchedHandler() {
  const args = Array.prototype.slice.call(arguments)

  if (args[1] && typeof args[1] === 'object' && !args[1].iopipe) {
    args[1].iopipe = wrapPatch()
  }

  return wrappedHandler.apply(this, args)
}

module.exports.handler = patchedHandler
