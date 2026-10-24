#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="nikhil92s.store"
hosted_zone_id="Z04914522O52OGMWMO2IV"

for instance in $@
do
    echo "Creating $instance EC2 Instance"

    instance_id=$(aws ec2 run-instances \
                    --image-id $ami_id \
                    --instance-type $instance_type \
                    --security-groups "roboshop-common" "roboshop-$instance"\
                    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
                    --query 'Instances[0].InstanceId' \
                    --output text
                )

    echo "$instance Instance ID :$instance_id"

    if [ $instance != "frontend" ]; then
        ip=$(aws ec2 describe-instances \
                --instance-ids $instance_id \
                --query 'Reservations[].Instances[].PrivateIpAddress' \
                --output text
            )
        r53_record=$instance.$domain_name
    else
        ip=$(aws ec2 describe-instances \
                --instance-ids $instance_id \
                --query 'Reservations[].Instances[].PublicIpAddress' \
                --output text
            )
        r53_record=$instance.$domain_name
    fi

    aws route53 change-resource-record-sets \
         --hosted-zone-id $hosted_zone_id \
         --change-batch '{"Changes": [
            {
            "Action": "UPSERT",
             "ResourceRecordSet": 
                {
                    "Name": ":'$r53_record'",
                     "Type": "A",
                      "ResourceRecords": [{"Value": "'$ip'"}]
                }
            }
            ]}'

echo "Update R53 Record for $instance"
done