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

dnf module disable nginx -y &>>$log_File
dnf module enable nginx:1.26 -y &>>$log_File
dnf install nginx -y &>>$log_File
validate $? "Installing NGINX"


systemctl enable nginx &>>$log_File
systemctl start nginx &>>$log_File
validate $? "Starting NGINX"

rm -rf /usr/share/nginx/html/* &>>$log_File
validate $? "Removing default Content"



curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>>$log_File
cd /usr/share/nginx/html &>>$log_File
unzip /tmp/frontend.zip &>>$log_File
validate $? "Downloading and UnZipping Frontend Code"


sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir"/roboshop.conf
validate $? "Updating all Domain Name"

cp "$script_dir"/roboshop.conf /etc/systemd/system/roboshop.conf 
validate $? "Copying Configuration"

nginx -t &>> $log_File
validate $? "Nginx Configuration"

systemctl restart nginx &>>$log_File
validate $? "Restarting Frontend"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $log_File