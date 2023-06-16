'use strict'

const notFoundDependency = require('path/not/found')

exports.handler = (event) => {
    return {
        statusCode: 200,
        body: JSON.stringify(event)
    }
}
