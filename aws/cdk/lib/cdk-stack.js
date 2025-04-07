const { Stack, Duration, RemovalPolicy, CfnOutput } = require('aws-cdk-lib');
const apigateway = require('aws-cdk-lib/aws-apigateway');
const lambda = require('aws-cdk-lib/aws-lambda');
const dynamodb = require('aws-cdk-lib/aws-dynamodb');
const ssm = require('aws-cdk-lib/aws-ssm');
const logs = require('aws-cdk-lib/aws-logs');
const cloudwatch = require('aws-cdk-lib/aws-cloudwatch');
const iam = require('aws-cdk-lib/aws-iam');

class CdkStack extends Stack {
  /**
   *
   * @param {Construct} scope
   * @param {string} id
   * @param {StackProps=} props
   */
  constructor(scope, id, props) {
    super(scope, id, props);

    // DynamoDB Table with PITR
    const table = new dynamodb.Table(this, 'AgricolaScoreTable', {
      tableName: 'agricola-score',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sessionId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: RemovalPolicy.RETAIN,
      timeToLiveAttribute: 'expiresAt',
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true }
    });

    // Add GSIs
    table.addGlobalSecondaryIndex({
      indexName: 'UserScoreIndex',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.NUMBER },
      projectionType: dynamodb.ProjectionType.ALL
    });

    table.addGlobalSecondaryIndex({
      indexName: 'SavedScoreIndex',
      partitionKey: { name: 'type', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.NUMBER },
      projectionType: dynamodb.ProjectionType.ALL
    });



    // Lambda Function with logging
    const webhookHandler = new lambda.Function(this, 'WebhookHandler', {
      functionName: 'agricola-score-webhook-handler',
      runtime: lambda.Runtime.RUBY_3_3,
      handler: 'app.handler',
      code: lambda.Code.fromAsset('../lambda'),
      environment: {
        DYNAMODB_TABLE: table.tableName,
        LINE_CHANNEL_SECRET: ssm.StringParameter.valueFromLookup(this, '/agricola-score/line-channel-secret'),
        LINE_CHANNEL_ACCESS_TOKEN: ssm.StringParameter.valueFromLookup(this, '/agricola-score/line-channel-access-token')
      },
      logRetention: logs.RetentionDays.TWO_WEEKS
    });

    // Grant Lambda permissions to access DynamoDB
    table.grantReadWriteData(webhookHandler);

    // Create or update API Gateway
    const api = new apigateway.RestApi(this, 'AgricolaScoreApi', {
      restApiName: 'agricola-score-api',
      cloudWatchRole: true,
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS
      },
      deployOptions: {
        accessLogDestination: new apigateway.LogGroupLogDestination(
          new logs.LogGroup(this, 'ApiGatewayAccessLogs', {
            logGroupName: 'agricola-score-api-logs',
            retention: logs.RetentionDays.TWO_WEEKS,
            removalPolicy: RemovalPolicy.RETAIN
          })
        ),
        accessLogFormat: apigateway.AccessLogFormat.jsonWithStandardFields()
      }
    });

    // Add /webhook endpoint with throttling
    const webhook = api.root.addResource('webhook');
    webhook.addMethod('POST', new apigateway.LambdaIntegration(webhookHandler), {
      apiKeyRequired: false
    });

    // Add throttling


    // CloudWatch Alarms
    new cloudwatch.Alarm(this, 'LambdaDurationAlarm', {
      metric: webhookHandler.metricDuration(),
      threshold: Duration.seconds(10).toMilliseconds(),
      evaluationPeriods: 1,
      alarmDescription: 'Lambda execution time > 10 seconds',
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING
    });

    new cloudwatch.Alarm(this, 'ApiGateway4xxAlarm', {
      metric: api.metricClientError(),
      threshold: 10,
      evaluationPeriods: 1,
      alarmDescription: 'API Gateway 4xx errors > 10',
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING
    });

    new cloudwatch.Alarm(this, 'ApiGatewaySuccessRateAlarm', {
      metric: new cloudwatch.MathExpression({
        expression: '100 - 100 * errors / requests',
        usingMetrics: {
          errors: api.metricServerError(),
          requests: api.metricCount()
        }
      }),
      threshold: 95,
      comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
      evaluationPeriods: 1,
      alarmDescription: 'API Gateway success rate < 95%',
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING
    });

    // DynamoDB throttles for different operations
    const operations = ['GetItem', 'PutItem', 'Query', 'Scan', 'UpdateItem', 'DeleteItem'];
    operations.forEach(operation => {
      new cloudwatch.Alarm(this, `DynamoDBThrottles${operation}Alarm`, {
        metric: table.metricThrottledRequestsForOperation(operation),
        threshold: 1,
        evaluationPeriods: 1,
        alarmDescription: `DynamoDB has throttled ${operation} requests`,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING
      });
    });

    // Output the API endpoint URL
    new CfnOutput(this, 'WebhookUrl', {
      value: `${api.url}webhook`,
      description: 'URL for LINE Webhook'
    });
  }
}

module.exports = { CdkStack };