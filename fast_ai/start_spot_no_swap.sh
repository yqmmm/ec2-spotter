# Parameters defaults
# The size of the root volume, in GB.
volume_size=128
# The name of the key file we'll use to log into the instance. create_vpc.sh sets it to aws-key-fast-ai
name=a
key_name=aws-key-$name
# Type of instance to launch
ec2spotter_instance_type=p2.xlarge
# In USD, the maximum price we are willing to pay.
bid_price=0.9

ami=ami-0403080dacdf781b0

subnetId=subnet-076e48a7bc0d0a7dd

securityGroupId=sg-053ed6db813de9513


# Read the input args
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --ami)
    ami="$2"
    shift # pass argument
    ;;
    --subnetId)
    subnetId="$2"
    shift # pass argument
    ;;
    --securityGroupId)
    securityGroupId="$2"
    shift # pass argument
    ;;
	--volume_size)
	volume_size="$2"
	shift # pass argument
	;;
	--key_name)
	key_name="$2"
	shift # pass argument
	;;
	--ec2spotter_instance_type)
	ec2spotter_instance_type="$2"
	shift # pass argument
	;;
	--bid_price)
	bid_price="$2"
	shift # pass argument
	;;
    *)
            # unknown option
    ;;
esac
shift # pass argument or value
done

cat >user-data.tmp <<EOF
#!/bin/sh
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
EOF

userData=$(base64 user-data.tmp | tr -d '\n');


# Create a config file to launch the instance.
cat >specs.tmp <<EOF 
{
  "ImageId" : "$ami",
  "InstanceType": "$ec2spotter_instance_type",
  "KeyName" : "$key_name",
  "EbsOptimized": true,
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/sda1",
      "Ebs": {
        "DeleteOnTermination": false, 
        "VolumeType": "gp2",
        "VolumeSize": $volume_size 
      }
    }
  ],
  "NetworkInterfaces": [
      {
        "DeviceIndex": 0,
        "SubnetId": "${subnetId}",
        "Groups": [ "${securityGroupId}" ],
        "AssociatePublicIpAddress": true
      }
  ],
  "UserData" : "${userData}"
}
EOF

# Request the spot instance
export request_id=`aws ec2 request-spot-instances --launch-specification file://specs.tmp --spot-price $bid_price --output="text" --query="SpotInstanceRequests[*].SpotInstanceRequestId"`

echo Waiting for spot request to be fulfilled...
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids $request_id  

# Get the instance id
export instance_id=`aws ec2 describe-spot-instance-requests --spot-instance-request-ids $request_id --query="SpotInstanceRequests[*].InstanceId" --output="text"`

echo Waiting for spot instance to start up...
aws ec2 wait instance-running --instance-ids $instance_id

echo Spot instance ID: $instance_id 

# Change the instance name
aws ec2 create-tags --resources $instance_id --tags --tags Key=Name,Value=$name-gpu-machine

# Get the instance IP
export instance_ip=`aws ec2 describe-instances --instance-ids $instance_id --filter Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].PublicIpAddress" --output=text`

echo Spot Instance IP: $instance_ip

# Clean up
rm specs.tmp
rm user-data.tmp
