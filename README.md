# BP-AMI-UPDATE-LAUNCH-TEMPLATE
I'll update the AMI in Launch Template

## Setup
* Clone the code available at [BP-AMI-UPDATE-LAUNCH-TEMPLATE](https://github.com/OT-BUILDPIPER-MARKETPLACE/BP-AMI-UPDATE-LAUNCH-TEMPLATE)
* Build the docker image

```
git submodule init
git submodule update
docker build -t ot/ami-update:0.1 .
```
