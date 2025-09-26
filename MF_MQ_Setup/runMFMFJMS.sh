#!/bin/bash

# Simple MQ JMS Compile and Run
# Usage: ./simple-mq-run.sh MainClassName

MQ_JAR="com.ibm.mq.allclient-9.3.4.1.jar"
MAIN_CLASS=${1:-"MyMQClient"}

echo "Compiling Java files..."
javac -cp "$MQ_JAR:." *.java

if [ $? -eq 0 ]; then
    echo "Running $MAIN_CLASS..."
    java -cp "$MQ_JAR:." $MAIN_CLASS
else
    echo "Compilation failed!"
    exit 1
fi
