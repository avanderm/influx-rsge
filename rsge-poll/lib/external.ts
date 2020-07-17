import * as cdk from '@aws-cdk/core';
import * as s3 from '@aws-cdk/aws-s3';

interface ExternalResourcesProps extends cdk.StackProps {
    artifactBucket: string;
}

export class ExternalResources extends cdk.Stack {
    public readonly artifactBucket: s3.IBucket;

    constructor(scope: cdk.Construct, id: string, props: ExternalResourcesProps) {
        super(scope, id, props);

        const artifactBucket = s3.Bucket.fromBucketName(this, 'ArtifactBucket', props.artifactBucket);

        this.artifactBucket = artifactBucket;
    }
}