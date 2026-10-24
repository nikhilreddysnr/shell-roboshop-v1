#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="nikhil92s.store"
hosted_zone_id="Z04914522O52OGMWMO2IV"

for instance in $@
do
    echo "Creating $instance EC2 Instance"
done