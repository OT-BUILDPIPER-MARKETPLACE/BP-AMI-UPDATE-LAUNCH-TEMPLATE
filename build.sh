#!/bin/bash

source  functions.sh
source  log-functions.sh
source  str-functions.sh
source  file-functions.sh
source  aws-functions.sh

aws sts get-caller-identity >/dev/null 2>&1


if [ $? -ne 0 ]; then
  logErrorMessage "AWS Invalid Creds"
else
  true
fi

ASG_DESCRIPTION=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${ASG_NAME} --region ${REGION} 2>&1)

if [ $? -ne 0 ]; then
  echo "Error: ASG name '$ASG_NAME' is not valid or does not exist."
else
  LT_NAME=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name --region ${REGION} ${ASG_NAME} --query 'AutoScalingGroups[*].LaunchTemplate.LaunchTemplateName' | head -n -1 | sed '1d' | awk -F'"' '{print $2}'| tr -d '"'`  
fi

logInfoMessage "I'll update the AMI in Launch Template :- [$LT_NAME]"
sleep  $SLEEP_DURATION

LAUNCH_TEMPLATE_ID=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name --region ${REGION} ${ASG_NAME} --query 'AutoScalingGroups[*].LaunchTemplate.LaunchTemplateId' | jq .[]| tr -d '"'`
AMI_ID=`aws ec2 describe-images --region ${REGION} --filters  "Name=tag:${AMI_TAG_1},Values=${AMI_TAG_1_VALUE}" "Name=tag:${AMI_TAG_2},Values=${AMI_TAG_2_VALUE}" --query 'sort_by(Images, &CreationDate)[].ImageId' --output text | awk '{print $NF; exit}'`

if [ -z "$AMI_ID" ]; then
  logErrorMessage "No AMI found with the specified tags."
else
  logInfoMessage "AMI ID: $AMI_ID"
fi

function UpdateTemplate(){
aws ec2 create-launch-template-version --launch-template-id ${LAUNCH_TEMPLATE_ID}  --version-description New-Version-${AMI_ID} --source-version 1 --launch-template-data "ImageId=${AMI_ID}" --region ${REGION}
}

logInfoMessage "Updating AMI in the Launch Template :- [$LT_NAME]"
UpdateTemplate $AMI_ID $LAUNCH_TEMPLATE_ID
logInfoMessage "Launch Template ID :- $LAUNCH_TEMPLATE_ID"
logInfoMessage "Updated AMI in the Launch Template"

function UPDATE_ASG_DESIRE_SIZE() {
  local ASG_NAME="$1"
  local percentage="$2"
  local current_capacity
  local original_capacity
  current_capacity=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" --query "AutoScalingGroups[0].DesiredCapacity" --output text)
  original_capacity="$current_capacity"
  new_capacity=$((current_capacity + (current_capacity * percentage / 100)))
  echo "Updating desired capacity for $ASG_NAME from $current_capacity to $new_capacity"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --desired-capacity "$new_capacity"
  sleep 40
  echo "Restoring desired capacity for $ASG_NAME to $original_capacity"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" --desired-capacity "$original_capacity"
}

logInfoMessage "Updating the intance capacity in percentage in the Auto Scaling Group"

UPDATE_ASG_DESIRE_SIZE $ASG_NAME $Instance_Capacity_In_Percentage


logInfoMessage "Congratulations Auto Scaling Group is successfully updated with percentage of the instances :- $Instance_Capacity_In_Percentage% !!!!"
generateOutput $ACTIVITY_SUB_TASK_CODE true "Congratulations Auto Scaling Group is successfully updated with percentage of the instances :- $Instance_Capacity_In_Percentage% !!!!"





