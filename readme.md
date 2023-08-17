# SST DART CUSTOM RUNTIME

This project presents a potential implementation of Dart within AWS Lambda using the SST Serverless framework. The aim is to deploy a custom runtime function effectively.

The concept centers on exploiting Dart's capability to be compiled into a binary executable. This allows us to create an AWS Lambda Function through a custom runtime.

Here are the key resources that guided the development of this approach:

- [Introducing a Dart runtime for AWS Lambda | AWS Open Source Blog (amazon.com)](https://aws.amazon.com/it/blogs/opensource/introducing-a-dart-runtime-for-aws-lambda/)
- [aws_lambda_dart_runtime - Dart API docs (awslabs.github.io)](https://awslabs.github.io/aws-lambda-dart-runtime/)
- [GitHub - katallaxie/aws-lambda-dart-runtime: A Dart runtime for AWS Lambda](https://github.com/katallaxie/aws-lambda-dart-runtime/)

---

## THE APPROACH

The foundational concept involves crafting a Dart Handler function utilizing the **aws_lambda_dart_runtime** package. This function is then registered within a singleton instance of the Runtime class.

Here are the manual steps that were followed to build this proof of concept. These steps are already incorporated into the project files, and they are elucidated here for clarity.

To begin, a Linux container is set up using Docker and the official Dart image:

```bash
docker run -v $PWD:/app -w /app -it dart /bin/bash
```

Within the Docker container, the following commands are executed:

- Fetch Dart dependencies

  ```bash
  dart pub get
  ```

- Compile the **main.dart** file into a Linux binary named **bootstrap** (assuming the main file is in the Dart project root)

  ```bas
  dart compile exe main.dart -o bootstrap
  ```

- Exit the container

  ```bash
  exit
  ```

At this point, the next step is to create a `lambda.zip` file containing the newly created `bootstrap` file. The following command is suggested for this purpose:

```bash
zip -j lambda.zip bootstrap
```

The resulting `lambda.zip` file can then be uploaded as a lambda function using the custom runtime.

---

## HOW IT WORKS

**IMPORTANT:** To use this approach, Docker must be installed and running.

This project was initiated as a standard **SST** project using the command:

```bash
npx create-sst@latest
```

Subsequently, the default `packages/funtions` folder was removed, and a new Dart project named `functions` was created within the `packages` folder:

```bash
dart create functions
```

Next, the **aws_lambda_dart_runtime** package was added to `packages/functions` using the katallaxie GitHub fork:

```yaml
dependencies:
  aws_lambda_dart_runtime:
    git:
      url: https://github.com/katallaxie/aws-lambda-dart-runtime
```

The `packages/functions/lib/functions.dart` file was rewritten as follows:

```dart
int calculate() {
  int counter = 0;
  for (var i = 0; i < 1000000; i++) {
    counter = counter + 1;
  }
  return counter;
}

```

A `main.dart` file was created within the `packages/functions/bin` folder:

```dart
import 'package:aws_lambda_dart_runtime/aws_lambda_dart_runtime.dart';
import 'package:aws_lambda_dart_runtime/runtime/context.dart';
import 'package:functions/functions.dart' as functions;

void main() async {
  /// This demo's handling an API Gateway request.
  calculate(Context context, AwsApiGatewayEvent event) async {
    final response = {"result": functions.calculate()};
    return AwsApiGatewayResponse.fromJson(response);
  }

  /// The Runtime is a singleton. You can define the handlers as you wish.
  Runtime()
    ..registerHandler<AwsApiGatewayEvent>(
      'calculate',
      calculate,
    )
    ..invoke();
}
```

A `dist` folder was also added to `packages/functions` to contain the `lambda.zip` file:

```bash
mkdir dist
```

Inside `packages/functions/`, a `build.sh` file was created with the necessary commands to compile the Linux binary:

```bash
#!/bin/sh

# Install dependencies
dart pub get

# build the binary
dart compile exe bin/main.dart -o dist/bootstrap

# Exit
exit
```

The script section of the `package.json` file in the SST root folder was modified to generate a new `lambda.zip` file whenever the SST app is deployed:

```json
  "scripts": {
    "dev": "npm run dartCompile && sst dev",
    "build": "npm run dartCompile && sst build",
    "deploy": "npm run dartCompile && sst deploy",
    "remove": "sst remove",
    "console": "sst console",
    "typecheck": "tsc --noEmit",
    "dartCompile": "cd packages/functions; rm dist/lambda.zip; rm dist/bootstrap; docker run -v $PWD:/app -w /app -it --entrypoint ./build.sh dart; cd dist; zip -j lambda.zip bootstrap; cd .. ; dart pub get; cd ..; cd .."
  },
```

Lastly, the `MyStack.ts` file was modified to create the Lambda function using the CDK function construct:

```typescript
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
      "GET /calculate/customRuntime": {
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
```

This approach enables the deployment of Dart code as an AWS Lambda Function using a Custom Runtime.

---

## DEPLOY AS A CONTAINER FUNCTION

It's also possible to use the SST Container Function support to deploy our function to AWS.
In this case, the we have to create a `Dockerfile` inside the `packages/funtions` path with the following code:

```bash
# GET THE OFFICIAL LAMBDA CONTAINER FOR THE PROVIDED AL2 RUNTIME
FROM public.ecr.aws/lambda/provided:al2

# COPY BOOTSTRAP FILE
COPY dist/bootstrap ${LAMBDA_RUNTIME_DIR}

# OPTIONAL SPECIFY FUNCTION HANDLER (WE CAN SPECIFY IT LATER IN MYSTACK.TS)
# CMD [ "hello.apigateway" ]
```

Lastly we can add to our `MyStack.ts` file the following construct:

```typescript
const api = new Api(stack, "api", {
  routes: {
    // ..
    "GET /calculate/containerRuntime": {
      function: {
        runtime: "container",
        handler: "packages/functions",
        container: {
          cmd: ["calculate"],
        },
      },
    },
  },
  // ...
});
```

## LIMITATIONS

This experimental approach comes with some limitations. Notably, it is not integrated into the SST Framework. There are known limitations related to testing and debugging functions. When using the `sst dev` command, the `lambda.zip` file will be uploaded to AWS, making it currently possible to observe invocations or console logs only via the official AWS Console.

Using the SST support for Container Functions it will be possible to observe invocations also in the SST Console but it we will probably have worst performaces both for cold start and execution.

---

## TROUBLESHOOTING

If errors arise when running the `build.sh` file, it may be necessary to grant appropriate permissions using the following command:

```bash
chmod +x build.sh
```
