import * as cdk from '@aws-cdk/core';
import * as codedeploy from '@aws-cdk/aws-codedeploy';
import * as codepipeline from '@aws-cdk/aws-codepipeline';
import * as codepipeline_actions from '@aws-cdk/aws-codepipeline-actions';
import * as iam from '@aws-cdk/aws-iam';
import * as s3 from '@aws-cdk/aws-s3';

interface PipelineStackProps extends cdk.StackProps {
    artifactBucket: s3.IBucket;
    githubTokenParameter: string;
    repository: string;
}

export class PipelineStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props: PipelineStackProps) {
    super(scope, id, props);

    const serviceRole = new iam.Role(this, 'ServiceRole', {
        assumedBy: new iam.ServicePrincipal('codedeploy.amazonaws.com'),
        managedPolicies: [
            iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AWSCodeDeployRole')
        ]
    });

    // const deploymentApplication = new codedeploy.ServerApplication(this, 'Application');
    const deploymentGroup = new codedeploy.ServerDeploymentGroup(this, 'DeploymentGroup', {
        // application: deploymentApplication,
        onPremiseInstanceTags: new codedeploy.InstanceTagSet({
            'Name': [
                'InfluxDB'
            ]
        }),
        role: serviceRole
    });

    const sourceOutput = new codepipeline.Artifact();

    new codepipeline.Pipeline(this, 'DeploymentPipeline', {
        artifactBucket: props.artifactBucket,
        stages: [
            {
                stageName: 'Source',
                actions: [
                    new codepipeline_actions.GitHubSourceAction({
                        actionName: 'Source',
                        branch: 'master',
                        oauthToken: cdk.SecretValue.secretsManager(props.githubTokenParameter),
                        output: sourceOutput,
                        owner: 'avanderm',
                        repo: props.repository,
                        trigger: codepipeline_actions.GitHubTrigger.WEBHOOK
                    })
                ]
            },
            {
                stageName: 'Deploy',
                actions: [
                    new codepipeline_actions.CodeDeployServerDeployAction({
                        actionName: 'Deploy',
                        deploymentGroup: deploymentGroup,
                        input: sourceOutput
                    })
                ]
            }
        ]
    });
  }
}
