#!/bin/bash

# Replace with your actual VPC and Subnet IDs
VPC_ID="vpc-02bfa5d8a7be30534"
SUBNET_IDS=("subnet-0f7918353f89974a5" "subnet-0fb29347165bec0df")

echo "Cleaning up resources in VPC: $VPC_ID"

# Terminate EC2 instances
echo "Terminating EC2 instances..."
for subnet in "${SUBNET_IDS[@]}"; do
  INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters Name=subnet-id,Values=$subnet \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)
  if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    echo "Terminated instances in $subnet: $INSTANCE_IDS"
  fi
done

# Delete NAT Gateways
echo "Deleting NAT Gateways..."
NAT_IDS=$(aws ec2 describe-nat-gateways \
  --filter Name=vpc-id,Values=$VPC_ID \
  --query "NatGateways[].NatGatewayId" \
  --output text)
if [ -n "$NAT_IDS" ]; then
  for nat in $NAT_IDS; do
    aws ec2 delete-nat-gateway --nat-gateway-id $nat
    echo "Deleted NAT Gateway: $nat"
  done
fi

# Delete ENIs
echo "Deleting Elastic Network Interfaces..."
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters Name=vpc-id,Values=$VPC_ID \
  --query "NetworkInterfaces[].NetworkInterfaceId" \
  --output text)
if [ -n "$ENI_IDS" ]; then
  for eni in $ENI_IDS; do
    aws ec2 delete-network-interface --network-interface-id $eni
    echo "Deleted ENI: $eni"
  done
fi

# Release Elastic IPs
echo "Releasing Elastic IPs..."
EIP_ALLOC_IDS=$(aws ec2 describe-addresses \
  --query "Addresses[?VpcId=='$VPC_ID'].AllocationId" \
  --output text)
if [ -n "$EIP_ALLOC_IDS" ]; then
  for alloc in $EIP_ALLOC_IDS; do
    aws ec2 release-address --allocation-id $alloc
    echo "Released Elastic IP: $alloc"
  done
fi

echo "Cleanup complete. You can now retry terraform destroy."
