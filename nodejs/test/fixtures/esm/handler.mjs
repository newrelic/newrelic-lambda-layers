const handler = async(event, context) => {
  return {
    "statusCode": 200,
    "body": `response body ${event.key}`
  }
}

export {handler}
