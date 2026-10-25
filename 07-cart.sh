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
    validate $? "Creating system user"
else
    echo "$(timestamp) [INFO] Roboshop User already Exist... ${Y}Skipping${N}"
fi

rm -rf /app
validate $? "Removing Old Code"

mkdir -p /app
validate $? "Creating App Directory"


curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip &>>$log_File
validate $? "Downloading Cart Application"


cd /app
unzip /tmp/cart.zip &>>$log_File
validate $? "Unzipping Cart Application"


cd /app
npm install &>>$log_File
validate $? "Installing Dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir"/cart.service
validate $? "Updating Redis and Catalogue Domain Name"

cp "$script_dir"/cart.service /etc/systemd/system/cart.service 
validate $? "Copying Cart Service"


systemctl daemon-reload &>>$log_File
systemctl enable cart &>>$log_File
systemctl start cart &>>$log_File
validate $? "Starting Cart"


systemctl restart cart &>>$log_File
validate $? "Restarting Cart"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $log_File