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

dnf module enable maven:3.9 -y &>>$log_File
dnf install maven java-25-openjdk-devel -y &>>$log_File
validate $? "Installing Java"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting Java 25 as default Java version"


echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting JAVA_HOME for Maven"



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


curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>>$log_File
validate $? "Downloading Shipping Application"


cd /app
unzip /tmp/shipping.zip &>>$log_File
validate $? "Unzipping Shipping Application"


cd /app
mvn clean package &>>$log_File
validate $? "Installing Dependencies"

mv target/shipping.jar shipping.jar
validate $? "Moving SHipping.jar file"



sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir"/shipping.service
validate $? "Updating Cart and MYSQL Domain Name"

cp "$script_dir"/shipping.service /etc/systemd/system/shipping.service 
validate $? "Copying Shipping Service"

dnf install mysql -y &>> $log_File
validate $? "Installing MySQL client"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $log_File )
if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "Loading shipping data"
else
    echo -e "$(timestamp) [INFO] Master data already loaded...${Y}SKIPPING${N}"
fi

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "Creating APP user"


systemctl daemon-reload &>>$log_File
systemctl enable shipping &>>$log_File
systemctl restart shipping &>>$log_File
validate $? "ReStarting?Starting Shipping"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo "$(timestamp) [INFO] ==== Script completed Execution =====" | tee -a $log_File