"use strict"
const test = Symbol.for('test.symbol')

// eslint-disable-next-line no-unused-vars
const handler = async function handler(event, context) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        "statusCode": 200,
        "body": `response body ${event.key}`
      })
    }, 100)
  })
}
handler[test] = 'value'

const nested = {
  asyncFunctionHandler: async function asyncFunctionHandler() {
    return {
      body: JSON.stringify('foo'),
      statusCode: 200,
    }
  }
}

module.exports.handler = handler
module.exports.nested = nested
