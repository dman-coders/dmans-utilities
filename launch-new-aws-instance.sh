#!/usr/bin/env bash


export EC2_KEYPAIR=dmanAWS    # THIS will be different for you
export EC2_KEYPAIR_FILE=~/.ec2/${EC2_KEYPAIR}.pem
export EC2_AMI=ami-60582132   # This is an ubuntu natty server base
export EC2_TYPE=t1.micro      # I found this out when choosing the base ami
export EC2_REMOTE_USER=ubuntu # This is specific to the instances, sometimes it's 'root'
export EC2_GROUP=sg-72277a20  # This is your own security group ID. Set it up in the UI first

ec2-run-instances $EC2_AMI --key $EC2_KEYPAIR --instance-type $EC2_TYPE --group $EC2_GROUP > ~/ec2-instance_info.txt

#... And you get a running machine, though we probably should also set a name?

# We have recorded the output of that command into ~/ec2-instance_info.txt
# so that we can work on the info it returned - the new ID we have been assigned.
# Get some info from it so we know where we are now talking about
export EC2_INSTANCE=`awk '$1 == "INSTANCE" { print $2 }' ~/ec2-instance_info.txt`

echo "Created a new instance, its id is"
echo "  $EC2_INSTANCE"

echo Wait for it to warm up (15s).
sleep 15

# At the time the request was made, we had not actually been assigned an address.
# Wait a bit, and then ask for it. Need to parse the text response for the bit we need.
ec2-describe-instances --filter "instance-id=$EC2_INSTANCE" > ~/ec2-instance_info2.txt 
export EC2_ADDRESS=`awk '$1 == "INSTANCE" { print $4 }' ~/ec2-instance_info2.txt`
export EC2_IP=`awk '$1 == "INSTANCE" { print $14 }' ~/ec2-instance_info2.txt`
# With this info, we can now connect to it like this :
echo "Now connecting to the remote server with"
echo "  ssh -i $EC2_KEYPAIR_FILE $EC2_REMOTE_USER@$EC2_ADDRESS"
echo "Try again in a few seconds if this fails... "
echo "To turn it off, run:"
echo "  ec2-terminate-instances $EC2_INSTANCE"

ssh -i $EC2_KEYPAIR_FILE $EC2_REMOTE_USER@$EC2_ADDRESS


