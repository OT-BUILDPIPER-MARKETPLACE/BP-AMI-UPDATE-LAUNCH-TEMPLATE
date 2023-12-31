FROM amazon/aws-cli

RUN yum update -y 
RUN yum install jq -y

ENV SLEEP_DURATION 0s

COPY build.sh .
ADD BP-BASE-SHELL-STEPS .

ENV ASG_NAME ""
ENV REGION ""
ENV AMI_TAG_1 ""
ENV AMI_TAG_1_VALUE ""
ENV AMI_TAG_2 ""
ENV AMI_TAG_2_VALUE ""
ENV Instance_Capacity_In_Percentage ""

ENV ACTIVITY_SUB_TASK_CODE BP-AMI-UPDATE-LAUNCH-TEMPLATE

ENTRYPOINT [ "./build.sh" ]