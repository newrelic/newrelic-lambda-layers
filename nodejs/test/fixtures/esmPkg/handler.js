const handler = async(event) => {
  return {
    "statusCode": 200,
    "body": `response body ${event.key}`
  }
}

export {handler}
