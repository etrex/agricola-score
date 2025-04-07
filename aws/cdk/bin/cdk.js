#!/usr/bin/env node

const cdk = require('aws-cdk-lib');
const { CdkStack } = require('../lib/cdk-stack');

const app = new cdk.App();

// Production stack
new CdkStack(app, 'agricola-score', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'ap-northeast-1'
  }
});