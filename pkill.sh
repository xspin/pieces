#!/bin/bash

kill_all() {
    for pid in `printf "$PSDATA" | awk '{print $2}'`
    do
        echo "kill $1 Pid $pid"
        kill $1 $pid 
    done
    PSDATA=`ps aux | grep "$PROG" | grep -v grep | grep -v kill`
    if [ ! -z "$PSDATA" ]; then
    echo '-------------------Fail----------------------'
        printf "$PSDATA" | grep --color=auto "$PROG" 
    fi

}

PROG=$1

if [ -z "$1" ]; then echo "Usage: `basename $0` [Program_Name]"; exit; fi

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
    [Yy]* ) kill_all $2; exit;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
esac