#!/bin/bash

# MQ JMS Compile and Run with JMS API
MQ_JAR="com.ibm.mq.allclient-9.3.4.1.jar"
JMS_JAR="javax.jms-api-2.0.1.jar"
MAIN_CLASS=${1:-"MyMQClient"}

# Check if both JARs exist
if [ ! -f "$MQ_JAR" ]; then
    echo "Error: $MQ_JAR not found!"
    exit 1
fi

if [ ! -f "$JMS_JAR" ]; then
    echo "Error: $JMS_JAR not found!"
    echo "Download with: wget https://repo1.maven.org/maven2/javax/jms/javax.jms-api/2.0.1/javax.jms-api-2.0.1.jar"
    exit 1
fi

echo "Compiling Java files..."
javac -cp "$MQ_JAR:$JMS_JAR:." *.java

if [ $? -eq 0 ]; then
    echo "Running $MAIN_CLASS..."
    java -cp "$MQ_JAR:$JMS_JAR:." $MAIN_CLASS
else
    echo "Compilation failed!"
    exit 1
fi
