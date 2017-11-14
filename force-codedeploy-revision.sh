#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
	echo "Usage: force-codedeploy-revision.sh <application_name> <deployment_group_name> <new_file_revision>"
	exit 1
fi

APPLICATION_NAME=$1
DEPLOYMENT_GROUP_NAME=$2
NEW_REVISION_FILE=$3

echo "Application Name: $APPLICATION_NAME"
echo "Deployment group Name: $DEPLOYMENT_GROUP_NAME"
echo "New revision file: $NEW_REVISION_FILE"

echo "Retrieving AWS Codeploy data for the deployment group ..."

# Retrieve the actual revision target of the deployment group
ACTUAL_REVISION=`aws deploy get-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP_NAME --query "*.*.s3Location.[bucket,key]" --output text`
BUCKET_NAME=`echo $ACTUAL_REVISION | tr -s ' ' | cut -d ' ' -f1`
ACTUAL_REVISION_FILE=`echo $ACTUAL_REVISION | tr -s ' ' | cut -d ' ' -f2`

ACTUAL_REVISION_FILE_S3="s3://$BUCKET_NAME/$ACTUAL_REVISION_FILE"
NEW_REVISION_FILE_S3="s3://$BUCKET_NAME/$NEW_REVISION_FILE"
echo "Actual revision file: $ACTUAL_REVISION_FILE_S3"
echo "New Revision file: $NEW_REVISION_FILE_S3"

# Checking that the new revision file exists on s3
echo "Checking the new revision file on s3..."
EXISTS=`aws s3 ls $NEW_REVISION_FILE_S3`
if [ -z "$EXISTS" ]; then
  echo "The new revision file cannot be found on s3"
  exit 1
fi
echo "New revision file found"

echo "The actual revision file $ACTUAL_REVISION_FILE_S3 will be deleted from s3, and the new revision file $NEW_REVISION_FILE_S3 will overwrite it"
aws s3 rm $ACTUAL_REVISION_FILE_S3
aws s3 cp $NEW_REVISION_FILE_S3 $ACTUAL_REVISION_FILE_S3

echo "Done !"