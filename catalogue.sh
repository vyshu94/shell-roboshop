#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  
VALIDATE $? "Downloading Code"