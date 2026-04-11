const { Stack, Duration, RemovalPolicy, CfnOutput } = require('aws-cdk-lib');
const lambda = require('aws-cdk-lib/aws-lambda');
const dynamodb = require('aws-cdk-lib/aws-dynamodb');
const logs = require('aws-cdk-lib/aws-logs');
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
        LINE_CHANNEL_SECRET_NAME: '/agricola-score/line-channel-secret',
        LINE_CHANNEL_ACCESS_TOKEN_NAME: '/agricola-score/line-channel-access-token'
      },
      logRetention: logs.RetentionDays.TWO_WEEKS,
      timeout: Duration.seconds(30),
      memorySize: 2048
    });

    // Lambda Function URL
    const functionUrl = webhookHandler.addFunctionUrl({
      authType: lambda.FunctionUrlAuthType.NONE
    });

    // Grant Lambda permissions to access DynamoDB
    table.grantReadWriteData(webhookHandler);

    // Grant Lambda permissions to read SSM parameters
    const secretArn = `arn:aws:ssm:${this.region}:${this.account}:parameter/agricola-score/*`;
    webhookHandler.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['ssm:GetParameter'],
      resources: [secretArn]
    }));

    // Output the Function URL
    new CfnOutput(this, 'WebhookFunctionUrl', {
      value: functionUrl.url,
      description: 'Lambda Function URL for LINE Webhook'
    });
  }
}

module.exports = { CdkStack };
