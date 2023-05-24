"use strict"

exports.handler = async (event, context, callback) => {
    callback(null, {
        "statusCode": 200,
        "body": `response body ${event.key}`
    })
}
