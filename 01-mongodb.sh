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
        echo "$2 Failed" | tee -a $log_File
        exit 1
    else
        echo "$2 Success" | tee -a $log_File
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo Repo"

dnf install mongodb-org -y &>>$log_File
validate $? "Installing Mongo DB"

systemctl enable mongod &>>$log_File
systemctl start mongod &>>$log_File
validate $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
validate $? "Updating Mongo Conf to AnyIP"

systemctl restart mongod
validate $? "Restarting MongoDB"