#!/bin/bash

kill_all() {
    for pid in `printf "$PSDATA" | awk '{print $2}'`
    do
        echo "kill Pid $pid"
        kill $pid || kill -9 $pid
    done
    PSDATA=`ps aux | grep "$PROG" | grep -v grep | grep -v kill`
    if [ ! -z "$PSDATA" ]; then
    echo '------------------------------------------'
        printf "$PSDATA" | grep --color=auto "$PROG" 
    fi

}

PROG=$1

if [ -z "$1" ]; then echo "Usage: kill.sh [Program_Name]"; exit; fi

PSDATA=`ps aux | grep "$1" | grep -v grep | grep -v kill`

if [ ! -z "$PSDATA" ]; then
    echo `ps aux|head -n1`
    printf "$PSDATA" | grep --color=auto "$1" 
fi
echo '------------------------------------------'

if  [ -z "$PSDATA" ]; then
    echo 'No progress found.'
    exit
fi

read -p "Do you want to kill all processes (y/n)? " yn
case $yn in
    [Yy]* ) kill_all; exit;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
esac