# aws-codedeploy-survival-kit
Some useful scripts for surviving aws codedeploy failures

## force-codedeploy-revision.sh

Like the name suggests it, this script allows you to force a codedeploy deployment group to use a specific revision. 
It can be useful when you are stucked with instances that are bootlooping because codedeploy fails to deploy the actual revision, and refuses to deploy a new revision.

### Usage
```
./force-codedeploy-revision.sh <application_name> <deployment_group_name> <new_file_revision>
```   

Note that the new file revision must be in the same bucket than the actual one, and the path must be relative to the root of the bucket.
For instance, if the current revision is `s3://mybucket/myapp/oldBrokenRevision.zip`, and we want to replace it by `s3://mybucket/myapp/newrevision.zip` :

```
./force-codedeploy-revision.sh my-app my-app-dev myapp/newrevision.zip
```

### Use case in details

When the autoscaling group launches a new instance, codedeploy install the last successful revision 'A' instead of the last deployed one 'B'.

We have very frequent issues with this behavior that leads our ASG to infinitely launching and killing new instances: 

* The revision 'A' is deployed successfully on the instances
* A few days later, one of the scripts in the appspec.yml fails when launching new instances.
  * The issue is fixed, and a new revision 'B' is deployed.
  * But instead of deploying the revision 'B', codedeploy continues to deploy the broken revision 'A' on new instances, which leads the ASG to infinitely launch/kill instances

This happens because whenever there is an autoscaling scale up event, Codedeploy always deploys the last successful revision that was deployed to the fleet, even if a more recent revision is available.
Codedeploy does not provide any solutions to fix this issue, the only known workaround are :

* delete the deployment group, recreating it, and redeploying the version 'B'. 
* erase the last successful revision file in S3, and replace it with the new, wanted, revision.

This script uses the second solution.
