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

export { handler }
