'use strict'

// eslint-disable-next-line no-unused-vars
const notFoundDependency = require('path/not/found')

exports.handler = (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(event)
  }
}

exports.nestedHandler = (event) => {
  return {
    statusCode: 200,
    body: JSON.stringify(event)
  }
}

