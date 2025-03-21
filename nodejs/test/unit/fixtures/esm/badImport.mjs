// eslint-disable-next-line no-unused-vars
import notFoundDependency from 'path/not/found'

export function handler(event) {
  return {
    statusCode: 200,
    body: JSON.stringify(event)
  }
}
export function nestedHandler(event) {
  return {
    statusCode: 200,
    body: JSON.stringify(event)
  }
}
