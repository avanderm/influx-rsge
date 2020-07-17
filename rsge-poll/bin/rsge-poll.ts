#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { AgentStack } from '../lib/agent';
import { PipelineStack } from '../lib/pipeline';
import { ExternalResources } from '../lib/external';

const account = process.env.CDK_DEPLOY_ACCOUNT || process.env.CDK_DEFAULT_ACCOUNT;
const region = process.env.CDK_DEPLOY_REGION || process.env.CDK_DEFAULT_REGION;

const app = new cdk.App();

const artifactBucket = `aws-codepipeline-${account}-${region}`;
const githubTokenParameter = app.node.tryGetContext('githubTokenParameter') || 'dud';
const repository = app.node.tryGetContext('repository') || 'influx-rsge';

const externalResources = new ExternalResources(app, 'ExternalResources', {
    env: {
        account: account,
        region: region
    },
    artifactBucket: artifactBucket
});

new AgentStack(app, 'InfluxAgentStack', {
    env: {
        account: account,
        region: region
    },
    tags: {
        Owner: 'antoine',
        Project: 'GrandExchange'
    }
});

new PipelineStack(app, 'GrandExchangeDeploymentStack', {
    env: {
        account: account,
        region: region
    },
    tags: {
        Owner: 'antoine',
        Project: 'GrandExchange'
    },
    artifactBucket: externalResources.artifactBucket,
    githubTokenParameter: githubTokenParameter,
    repository: repository
});
