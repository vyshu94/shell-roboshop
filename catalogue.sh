#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.dawsproject.online

#check root user or not

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then 
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>LOGS_FILE
VALIDATE $? "disabled the default node version" 

dnf module enable nodejs:20 -y &>>LOGS_FILE
VALIDATE $? "Enabled nodejs version 20" 

dnf install nodejs -y &>>LOGS_FILE
VALIDATE $? "Installed nodejs"

id roboshop &>>LOGS_FILE
if [ $? -ne 0 ]; then
    #creating system user
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating system user"
else
    echo -e "Roboshop user already exists ... $Y Skipping $N..."
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  
VALIDATE $? "Downloading Code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing the files in app folder"

unzip /tmp/catalogue.zip &>>LOGS_FILE
VALIDATE $? "unzip catalogue code"

npm install &>>LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>LOGS_FILE
systemctl start catalogue
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading Products"
else
    echo -e "products already loaded... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"