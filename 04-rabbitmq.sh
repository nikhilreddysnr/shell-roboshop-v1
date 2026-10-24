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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_File
validate $? "Adding RabbitMQ Repo"

dnf install erlang rabbitmq-server -y &>>$log_File
validate $? "Installing RabbitMQ"

systemctl enable rabbitmq-server &>>$log_File
systemctl start rabbitmq-server &>>$log_File
validate $? "ENabling And Starting Rabbit MQ"

rabbitmqctl list_users | grep -qw "roboshop" &>>$log_File
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>>$log_File
    validate $? "Creating RabbitMQ user for Roboshop"    
else
    echo -e "$(timestamp) [INFO] RabbitMQ user already exist...${Y}SKIPPING${N}" 
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_File
validate $? "Setting permissions for RabbitMQ user for Roboshop"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $log_File