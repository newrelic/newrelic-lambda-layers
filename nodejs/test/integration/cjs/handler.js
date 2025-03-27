'use strict'

const { stringify } = JSON

module.exports.contextDoneHandler = function contextDoneHandler(event, context) {
  context.done(null, {
    body: stringify('foo'),
    statusCode: 200,
  })
}

module.exports.contextDoneHandlerDeferred = function contextDoneHandlerDeferred(event, context) {
  setTimeout(
    () =>
      context.done(null, {
        body: stringify('foo'),
        statusCode: 200,
      }),
    100,
  )
}

module.exports.contextSucceedHandler = function contextSucceedHandler(event, context) {
  context.succeed({
    body: stringify('foo'),
    statusCode: 200,
  })
}

module.exports.contextSucceedHandlerDeferred = function contextSucceedHandlerDeferred(event, context) {
  setTimeout(
    () =>
      context.succeed({
        body: stringify('foo'),
        statusCode: 200,
      }),
    100,
  )
}

module.exports.callbackHandler = function callbackHandler(event, context, callback) {
  callback(null, {
    body: stringify('foo'),
    statusCode: 200,
  })
}

module.exports.callbackHandlerDeferred = function callbackHandlerDeferred(event, context, callback) {
  setTimeout(
    () =>
      callback(null, {
        body: stringify('foo'),
        statusCode: 200,
      }),
    100,
  )
}

module.exports.promiseHandler = function promiseHandler() {
  return Promise.resolve({
    body: stringify('foo'),
    statusCode: 200,
  })
}

module.exports.promiseHandlerDeferred = function promiseHandlerDeferred() {
  return new Promise((resolve) => {
    setTimeout(
      () =>
        resolve({
          body: stringify('foo'),
          statusCode: 200,
        }),
      100,
    )
  })
}

module.exports.asyncFunctionHandler = async function asyncFunctionHandler() {
  return {
    body: stringify('foo'),
    statusCode: 200,
  }
}
// we deliberately test the case where a 'callback' is defined
// in the handler, but a promise is being returned to protect from a
// potential naive implementation, e.g.
//
// const { promisify } = 'utils'
// const promisifiedHandler = handler.length === 3 ? promisify(handler) : handler
//
// if someone would return a promise, but also defines callback, without using it
// the handler would not be returning anything
module.exports.promiseWithDefinedCallbackHandler = function promiseWithDefinedCallbackHandler(
  event, // eslint-disable-line no-unused-vars
  context, // eslint-disable-line no-unused-vars
  callback, // eslint-disable-line no-unused-vars
) {
  return Promise.resolve({
    body: stringify('Hello Promise!'),
    statusCode: 200,
  })
}

module.exports.contextSucceedWithContextDoneHandler = function contextSucceedWithContextDoneHandler(event, context) {
  context.succeed({
    body: stringify('Hello Context.succeed!'),
    statusCode: 200,
  })
  context.done(null, {
    body: stringify('Hello Context.done!'),
    statusCode: 200,
  })
}

module.exports.callbackWithContextDoneHandler = function callbackWithContextDoneHandler(event, context, callback) {
  callback(null, {
    body: stringify('Hello Callback!'),
    statusCode: 200,
  })
  context.done(null, {
    body: stringify('Hello Context.done!'),
    statusCode: 200,
  })
}

module.exports.callbackWithPromiseHandler = function callbackWithPromiseHandler(event, context, callback) {
  callback(null, {
    body: stringify('Hello Callback!'),
    statusCode: 200,
  })
  return Promise.resolve({
    body: stringify('Hello Promise!'),
    statusCode: 200,
  })
}

module.exports.callbackInsidePromiseHandler = function callbackInsidePromiseHandler(event, context, callback) {
  return new Promise((resolve) => {
    callback(null, {
      body: stringify('Hello Callback!'),
      statusCode: 200,
    })
    resolve({
      body: stringify('Hello Promise!'),
      statusCode: 200,
    })
  })
}

module.exports.throwExceptionInPromiseHandler = async() => {
  throw NaN
}

module.exports.throwExceptionInCallbackHandler = () => {
  throw NaN
}

module.exports.NoAnswerInPromiseHandler = async() => {}

module.exports.BadAnswerInPromiseHandler = async() => {
  return {}
}

module.exports.BadAnswerInCallbackHandler = (event, context, callback) => {
  callback(null, {})
}

module.exports.TestPathVariable = (event, context, callback) => {
  callback(null, {
    body: stringify(event.path),
    statusCode: 200,
  })
}

module.exports.TestResourceVariable = (event, context, callback) => {
  callback(null, {
    body: stringify(event.resource),
    statusCode: 200,
  })
}

module.exports.TestPayloadSchemaValidation = (event, context, callback) => {
  callback(null, {
    body: stringify(event.body),
    statusCode: 200,
  })
}

module.exports.nested = {
  contextDoneHandler: function contextDoneHandler(event, context) {
    context.done(null, {
      body: JSON.stringify('foo'),
      statusCode: 200,
    })
  },

  contextSucceedHandler: function contextSucceedHandler(event, context) {
    context.succeed({
      body: JSON.stringify('foo'),
      statusCode: 200,
    })
  },

  callbackHandler: function callbackHandler(event, context, callback) {
    callback(null, {
      body: JSON.stringify('foo'),
      statusCode: 200,
    })
  },

  promiseHandler: function promiseHandler() {
    return Promise.resolve({
      body: JSON.stringify('foo'),
      statusCode: 200,
    })
  },

  asyncFunctionHandler: async function asyncFunctionHandler() {
    return {
      body: JSON.stringify('foo'),
      statusCode: 200,
    }
  },
}
