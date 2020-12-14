import { APIGatewayProxyEvent } from "aws-lambda";

const DEFAULT_OPTIONS = { method: "GET", headers: {}, query: {}, path: "/" }

export function constructAPIGwEvent(message: any, options: any = DEFAULT_OPTIONS): APIGatewayProxyEvent {
  const opts = Object.assign({}, DEFAULT_OPTIONS, options);
  return {
    httpMethod: opts.method,
    path: opts.path,
    queryStringParameters: opts.query,
    headers: opts.headers,
    body: opts.rawBody || JSON.stringify(message),
    multiValueHeaders: {},
    multiValueQueryStringParameters: {},
    isBase64Encoded: false,
    pathParameters: opts.pathParameters || {},
    stageVariables: {},
    requestContext: null,
    resource: null,
  }
}
