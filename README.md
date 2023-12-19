# aws-sam-typescript-layers-example

This project contains source code and supporting files for a serverless application that is written in TypeSctipt using shared layers for dependencies with following considerations in mind:

- Keeping the local development experience mostly unchanged compared to pure Node.js SAM app: no moving `package.json` to other places or otherwise change the directory structure before deployment.
- No running `sam build` on every change in a function handler code.
- Keeping generated JS code as close to TS source as possible, preserving the file layout (don't bundle everything into a single file like webpack does).
- Keeping dependencies in a separate layer shared between related Lambdas: it makes deploys faster as you only need to update function code and not its dependencies. Also, Lambda functions have the size limit which can be easily surpassed with heavy dependencies, shared layers allow us to keep coloring between the lines.
- Keeping deploys as vanilla as possible: `sam build` and `sam deploy`, with no extra CLI magic.

In short, a Lambda with TypeScript and shared layers must behave the same way as a freshly generated Lambda on pure Node.js.

To create your own serverless application based this example you can use [this SAM template](https://github.com/Envek/cookiecutter-aws-sam-typescript-layers):

```sh
sam init --location gh:Envek/cookiecutter-aws-sam-typescript-layers
```

This sample application is artificially created set of Lambda function that does arbitrary CRUD operations in a way that better display benefits and features of this solution, like partial transpiling of only used source files.

This repo includes the following files and folders:

- `src` - Code for the application's Lambda function written in TypeScript.
- `events` - Invocation events that you can use to invoke the function.
- `__tests__` - Unit tests for the application code. 
- `template.yml` - A template that defines the application's AWS resources.

The application uses several AWS resources, including Lambda functions, an API Gateway API, and Amazon DynamoDB tables. These resources are defined in the `template.yml` file in this project. You can update the template to add AWS resources through the same deployment process that updates your application code.

If you prefer to use an integrated development environment (IDE) to build and test your application, you can use the AWS Toolkit.  
The AWS Toolkit is an open-source plugin for popular IDEs that uses the AWS SAM CLI to build and deploy serverless applications on AWS. The AWS Toolkit also adds step-through debugging for Lambda function code. 

To get started, see the following:

* [PyCharm](https://docs.aws.amazon.com/toolkit-for-jetbrains/latest/userguide/welcome.html)
* [IntelliJ](https://docs.aws.amazon.com/toolkit-for-jetbrains/latest/userguide/welcome.html)
* [VS Code](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/welcome.html)
* [Visual Studio](https://docs.aws.amazon.com/toolkit-for-visual-studio/latest/user-guide/welcome.html)

## Deploy the sample application

The AWS SAM CLI is an extension of the AWS CLI that adds functionality for building and testing Lambda applications. It uses Docker to run your functions in an Amazon Linux environment that matches Lambda. It can also emulate your application's build environment and API.

To use the AWS SAM CLI, you need the following tools:

* AWS SAM CLI - [Install the AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).
* Node.js - [Install Node.js 12](https://nodejs.org/en/), including the npm package management tool.
* Docker - [Install Docker community edition](https://hub.docker.com/search/?type=edition&offering=community).

To build and deploy your application for the first time, run the following in your shell:

```bash
sam build
sam deploy --guided
```

The first command will build the source of your application: installs dependencies that are defined in `package.json`, creates a deployment package, and saves it in the `.aws-sam/build` folder.

The second command will package and deploy your application to AWS, with a series of prompts:

* **Stack Name**: The name of the stack to deploy to CloudFormation. This should be unique to your account and region, and a good starting point would be something matching your project name.
* **AWS Region**: The AWS region you want to deploy your app to.
* **Confirm changes before deploy**: If set to yes, any change sets will be shown to you before execution for manual review. If set to no, the AWS SAM CLI will automatically deploy application changes.
* **Allow SAM CLI IAM role creation**: Many AWS SAM templates, including this example, create AWS IAM roles required for the AWS Lambda function(s) included to access AWS services. By default, these are scoped down to minimum required permissions. To deploy an AWS CloudFormation stack which creates or modified IAM roles, the `CAPABILITY_IAM` value for `capabilities` must be provided. If permission isn't provided through this prompt, to deploy this example you must explicitly pass `--capabilities CAPABILITY_IAM` to the `sam deploy` command.
* **Save arguments to samconfig.toml**: If set to yes, your choices will be saved to a configuration file inside the project, so that in the future you can just re-run `sam deploy` without parameters to deploy changes to your application.

The API Gateway endpoint API will be displayed in the outputs when the deployment is complete.

### Building of additional layers and Lambda itself

To decrease size of Lambda functions, runtime dependencies are extracted into Lambda Layer.

However, many guides (including Amazon ones) like [1](https://aws.amazon.com/blogs/compute/working-with-aws-lambda-and-lambda-layers-in-aws-sam/) or [2](https://medium.com/@anjanava.biswas/nodejs-runtime-environment-with-aws-lambda-layers-f3914613e20e) propose to move `package.json` to another folder which breaks local development and testing.

To keep local workflow, building of Lambda itself and its layers was changed from default “automagic” of SAM (`sam build` automatically copies code, installs packages, and cleans up, but this process can't be customized) to explicit steps defined in `Makefile` as per [Building layers](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/building-layers.html) doc.

So, now on `sam build` command:
 1. Only `src` folder is copied into function itself (however it is renamed into `dist` and contains TypeScript transpiled to JavaScript).
 2. packages are installed into separate layer (`package-lock.json` is also copied for reference)
 3. Local project layout isn't changed at all.

`sam deploy` will update layer with dependencies only if number or versions of packages were changed.

## Use the AWS SAM CLI to build and test locally

Copy `env.json.sample` to `env.json`:

```sh
cp -n env.json{.sample,}
```

Create some DynamoDB table in AWS console at https://console.aws.amazon.com/dynamodb/home#tables: for local development and write its name into `env.json` (make sure that region in your local configuration matches with console).

**Warning:** Make sure you don't have `.aws-sam` directory (built SAM template), because if you do, `sam local invoke` will use code from it and won't see your code changes.

If you have some kind of Procfile launcher like [Overmind](https://github.com/DarthSim/overmind) (highly recommended!) you can use it to start both TypeScript compiler in watch mode and local API gateway simultaneously:

```bash
$ overmind start
```

And that's it: now you can head over to http://localhost:3000/ to hit `getAllItemsFunction`!

But, sure, you still can start components independently:

Start Typescript compiler in watch mode to recompile your code on change (_instead_ of running `sam build` command).

```bash
$ npm run watch
```

Test a single function by invoking it directly with a test event. An event is a JSON document that represents the input that the function receives from the event source. Test events are included in the `events` folder in this project.

Run functions locally and invoke them with the `sam local invoke` command.

```bash
my-application$ sam local invoke putItemFunction --env-vars env.json --event events/event-post-item.json
my-application$ sam local invoke getAllItemsFunction --env-vars env.json --event events/event-get-all-items.json
```

The AWS SAM CLI can also emulate your application's API. Use the `sam local start-api` command to run the API locally on port 3000.

```bash
my-application$ sam local start-api --env-vars=env.json
my-application$ curl -X POST http://localhost:3000/ -d '{"id": "curl1","name": "Created with cURL"}'
my-application$ curl http://localhost:3000/
```

The AWS SAM CLI reads the application template to determine the API's routes and the functions that they invoke. The `Events` property on each function's definition includes the route and method for each path.

```yaml
      Events:
        Api:
          Type: Api
          Properties:
            Path: /
            Method: GET
```

### Debugging

You can debug with external debugger by this manual: [Step-through debugging Node.js functions locally ](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-using-debugging-nodejs.html)

 1. Run `sam local invoke` with `--debug-port` option.

    ```sh
    $ sam local invoke getAllItemsFunction --env-vars=env.json --event events/event-get-all-items.json --debug-port 5858
    ```

    It will wait for debugger to attach before starting execution of the function.

 2. Place a breakpoint where needed (yes, right in TypeScript code).

 3. Start external debugger. In Visual Studio Code you can just press F5.

## Add a resource to your application
The application template uses AWS SAM to define application resources. AWS SAM is an extension of AWS CloudFormation with a simpler syntax for configuring common serverless application resources, such as functions, triggers, and APIs. For resources that aren't included in the [AWS SAM specification](https://github.com/awslabs/serverless-application-model/blob/master/versions/2016-10-31.md), you can use the standard [AWS CloudFormation resource types](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html).

Update `template.yml` to add a dead-letter queue to your application. In the **Resources** section, add a resource named **MyQueue** with the type **AWS::SQS::Queue**. Then add a property to the **AWS::Serverless::Function** resource named **DeadLetterQueue** that targets the queue's Amazon Resource Name (ARN), and a policy that grants the function permission to access the queue.

```yaml
Resources:
  MyQueue:
    Type: AWS::SQS::Queue
  getAllItemsFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: src/handlers/get-all-items.getAllItemsHandler
      Runtime: nodejs18.x
      DeadLetterQueue:
        Type: SQS 
        TargetArn: !GetAtt MyQueue.Arn
      Policies:
        - SQSSendMessagePolicy:
            QueueName: !GetAtt MyQueue.QueueName
```

The dead-letter queue is a location for Lambda to send events that could not be processed. It's only used if you invoke your function asynchronously, but it's useful here to show how you can modify your application's resources and function configuration.

Deploy the updated application.

```bash
my-application$ sam deploy
```

Open the [**Applications**](https://console.aws.amazon.com/lambda/home#/applications) page of the Lambda console, and choose your application. When the deployment completes, view the application resources on the **Overview** tab to see the new resource. Then, choose the function to see the updated configuration that specifies the dead-letter queue.

## Fetch, tail, and filter Lambda function logs

To simplify troubleshooting, the AWS SAM CLI has a command called `sam logs`. `sam logs` lets you fetch logs that are generated by your Lambda function from the command line. In addition to printing the logs on the terminal, this command has several nifty features to help you quickly find the bug.

**NOTE:** This command works for all Lambda functions, not just the ones you deploy using AWS SAM.

```bash
my-application$ sam logs -n putItemFunction --stack-name sam-app --tail
```

**NOTE:** This uses the logical name of the function within the stack. This is the correct name to use when searching logs inside an AWS Lambda function within a CloudFormation stack, even if the deployed function name varies due to CloudFormation's unique resource name generation.

You can find more information and examples about filtering Lambda function logs in the [AWS SAM CLI documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-logging.html).

## Unit tests

Tests are defined in the `__tests__` folder in this project. Use `npm` to install the [Jest test framework](https://jestjs.io/) and run unit tests.

```bash
my-application$ npm install
my-application$ npm run test
```

## Cleanup

To delete the sample application that you created, use the AWS CLI. Assuming you used your project name for the stack name, you can run the following:

```bash
aws cloudformation delete-stack --stack-name aws-sam-typescript-layers-example
```

## Resources

For an introduction to the AWS SAM specification, the AWS SAM CLI, and serverless application concepts, see the [AWS SAM Developer Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html).

Next, you can use the AWS Serverless Application Repository to deploy ready-to-use apps that go beyond Hello World samples and learn how authors developed their applications. For more information, see the [AWS Serverless Application Repository main page](https://aws.amazon.com/serverless/serverlessrepo/) and the [AWS Serverless Application Repository Developer Guide](https://docs.aws.amazon.com/serverlessrepo/latest/devguide/what-is-serverlessrepo.html).

## License

This example is licensed under the terms of the [MIT license](https://opensource.org/licenses/MIT). See [LICENSE](./LICENSE) file for details.
