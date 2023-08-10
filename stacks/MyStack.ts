import * as cdk from "aws-cdk-lib/aws-lambda";
import { StackContext, Api } from "sst/constructs";

export function API({ stack }: StackContext) {
  // Create Lambda Function using cdk Contruct configuring a Custin Runtime and uploading the binary generated from dart file
  const calculateCdkFn = new cdk.Function(stack, "calculate", {
    runtime: cdk.Runtime.PROVIDED_AL2,
    handler: "calculate",
    code: cdk.Code.fromAsset("packages/functions/dist/lambda.zip"),
    tracing: cdk.Tracing.ACTIVE,
  });

  const api = new Api(stack, "api", {
    routes: {
      "GET /calculate": {
        type: "function",
        cdk: {
          function: calculateCdkFn,
        },
      },
    },
  });

  stack.addOutputs({
    ApiEndpoint: api.url,
  });
}
