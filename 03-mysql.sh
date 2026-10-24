#!/bin/bash

logs_Folder="/var/log/shell-practice"
log_File="${logs_Folder}/${0}.log"
userId=$(id -u)

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

echo "$(timestamp) [INFO] =======Script Started Execution=========" | tee -a $logs_file

dnf module enable mysql:8.4 -y &>>$log_File
dnf install mysql-server -y &>>$log_File
validate $? "$(timestamp) [INFO] Installing MySQL"

systemctl enable mysqld &>>$log_File
systemctl start mysqld &>>$log_File
validate $? "$(timestamp) [INFO] Starting MySQL"

mysql_secure_installation --set-root-pass RoboShop@1
validate $? "Setup MySQL Root Password"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $logs_file