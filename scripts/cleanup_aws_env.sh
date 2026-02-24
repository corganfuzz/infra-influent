#!/bin/bash

set -e

# Configuration
REGION=$(aws configure get region)
echo "------------------------------------------------"
echo "AWS Environment Cleanup | Region: ${REGION}"
echo "------------------------------------------------"

# 1. Identify VPCs
VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text)

if [ -z "$VPCS" ]; then
    echo "No VPCs found. Environment is clean."
    exit 0
fi

for VPC_ID in $VPCS; do
    echo "Processing VPC: ${VPC_ID}"

    # Delete Internet Gateways
    IGWS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --query 'InternetGateways[*].InternetGatewayId' --output text)
    for IGW in $IGWS; do
        echo "  - Detaching and deleting IGW: ${IGW}"
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW"
    done

    # Delete Subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query 'Subnets[*].SubnetId' --output text)
    for SUBNET in $SUBNETS; do
        echo "  - Deleting Subnet: ${SUBNET}"
        aws ec2 delete-subnet --subnet-id "$SUBNET"
    done

    # Delete Route Tables (skipping the main one which gets deleted with the VPC)
    RTBS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text)
    for RTB in $RTBS; do
        echo "  - Deleting Route Table: ${RTB}"
        aws ec2 delete-route-table --route-table-id "$RTB"
    done

    # Delete Security Groups (skipping the default one)
    SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
    for SG in $SGS; do
        echo "  - Deleting Security Group: ${SG}"
        aws ec2 delete-security-group --group-id "$SG"
    done

    # Finally, delete the VPC
    echo "  - Deleting VPC: ${VPC_ID}"
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
done

echo "------------------------------------------------"
echo "Cleanup Complete. AWS environment is pristine."
echo "------------------------------------------------"
