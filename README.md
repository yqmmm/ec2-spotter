# AWS Persistant Spot Intance
Forked from https://github.com/atramos/ec2-spotter

EC2 spot instances behave much like regular instances, but are cheaper. 
Normally, they can only be inited from an AMI image, not EBS volume, resetting any changes made along the way.
This script enables you to continue with your Spot instance where you left off.

Refer to this medium post for information on how to use this:
https://medium.com/slavv/learning-machine-learning-on-the-cheap-persistent-aws-spot-instances-668e7294b6d8

## Changes by yqmmm

I made some changes so I can better use it.

### alias
There are some alias I use, the most commonly used one is `aws-start`,.

```bash
alias aws-start=$AWS_DIR/ec2-spotter/fast_ai/start.sh
alias aws-get-p2='export instanceId=`aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped,Name=instance-type,Values=p2.xlarge" --query "Reservations[0].Instances[0].InstanceId"` && echo $instanceId'
alias aws-ip='export instanceIp=`aws ec2 describe-instances --filters "Name=instance-id,Values=$instanceId" --query "Reservations[0].Instances[0].PublicIpAddress"` && echo $instanceIp'
alias aws-ssh='ssh -i ~/.ssh/tokyo.pem ubuntu@$instanceIp'
alias aws-stop='aws ec2 stop-instances --instance-ids $instanceId'
alias aws-volume='aws ec2 describe-volumes'
```

### Workflow
I think it is better to mount the volume, because you can choose whatever instance type you want, so you can choose a cheaper machine when you don't actually need the GPU. And now Amazon has this Deep Learning AMI, you can always stay tuned and don't have to worry about upgrading your software. 

The only thing I use now is the `/faste_ai/start.sh`, you can specify the instance type you want, and change other stuff in the `start.sh` file. 

The only you have to change before using this script is the subnetId, securityGroup and stuff like that in `start.sh`. You'll be able to set them quickly with `fast_ai/create_vpc.sh`.

### Which Region
For people in China, the best choice is alwys the Tokyo Region. Seoul is the cheapest, but the connection is unstable. I have tested Seoul, Tokyo and Singapore, both the connection with Singapore and Seoul actually have to route from Tokyo. That's why Tokyo is the best choice.