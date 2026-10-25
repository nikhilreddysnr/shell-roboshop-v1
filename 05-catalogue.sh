#!/bin/bash

logs_Folder="/var/log/shell-practice"
log_File="${logs_Folder}/${0}.log"
userId=$(id -u)
script_dir=$( dirname "$(realpath "${0}")")
domain_name=nikhil92s.store
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


if [ $userId -ne 0 ]; then
    echo "Please execute this command with root user or sudo"
    exit 1
fi

echo -e "${Y}Proceeding${N}...."

mkdir -p $logs_Folder

validate()
{
    if [ $1 -ne 0 ]; then
        echo "$(timestamp) [ERROR] $2 Failed" | tee -a $log_File
        exit 1
    else
        echo "$(timestamp) [INFO] $2 Success" | tee -a $log_File
    fi
}

timestamp()
{
    date "+%F %T"
}

echo "$(timestamp) [INFO] =======Script Started Execution=========" | tee -a $log_File

dnf module disable nodejs -y &>>$log_File
dnf module enable nodejs:24 -y &>>$log_File
dnf install nodejs -y &>>$log_File
validate $? "Installing NodeJs"


id roboshop &>>$log_File
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_File
else
    echo "$(timestamp) [INFO] Roboshop User already Exist... ${Y}Skipping${N}"
fi

rm -rf /app
validate $? "Removing Old Code"

mkdir -p /app
validate $? "Creating App Directory"


curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>>$log_File
validate $? "Downloading Catalogue Application"


cd /app
unzip /tmp/catalogue.zip &>>$log_File
validate $? "Unzipping Catalogue Application"


cd /app
npm install &>>$log_File
validate $? "Installing Dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir"/catalogue.service
validate $? "Updating MongoDB Domain Name"

cp "$script_dir"/catalogue.service /etc/systemd/system/catalogue.service 
validate $? "Copying Catalogue Service"


systemctl daemon-reload &>>$log_File
systemctl enable catalogue &>>$log_File
systemctl start catalogue &>>$log_File
validate $? "Starting Catalogue"

cp "$script_dir"/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo Repo"

dnf install mongodb-mongosh -y &>>$log_File
validate $? "Installing MongoDB Client"

product_count = $(mongosh --host <MONGODB-SERVER-IPADDRESS> --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2>>$log_File)
validate $? "Connecting to Mongo DB"

if [ $product_count -eq 0 ]; then
    mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>>$log_File
    validate $? "Loading Products"
else
    echo "$(timestamp) [INFO] Products already loaded...${Y}Skipping${N}"
fi

systemctl restart catalogue &>>$log_File
validate $? "Restarting catalogue"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $log_File