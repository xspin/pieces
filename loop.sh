#!/bin/bash
exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit
}

if [ -z "$1" ]; then
    echo "Usage: `basename $0` 'CMD' [SEC]"
    exit
fi

SEC=$2
if [ -z "$SEC" ]; then
    SEC=1
fi

while true
do
    $1 
    echo `date +%Y-%m-%d_%H:%M:%S` "$1" 1>&2
    sleep $SEC
    exitimer
done
