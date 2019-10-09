#!/bin/bash

log() {
    echo `date +[%Y-%m-%d_%H:%M:%S]` $*
}

exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit;
}

usage() {
pn=`basename $0`
printf """Usage: $pn [OPTION] [IP] PORT 
  -h\t print this help.
  -d\t [default 200] data size to transfer (unit is 10MB).
  -t\t [default 40] transfer timeout (minutes).
  -p\t [default 60] time pivot (1~60).
  -o\t [default /dev/null] store data to FILE
Example:
    Sender: $pn Local_Port
    Reciver: $pn Remote_IP Remote_Port
"""
}

DATASIZE=200 #x10MB
TIMEOUT=40 #min
PIVOT=60 # 1~60 min
FILE='/dev/null'

while getopts 'hd:t:p:o:' OPT; do
    case $OPT in
        h) usage; exit;;
        d) DATASIZE="$OPTARG";;
        t) TIMEOUT="$OPTARG";;
        p) PIVOT="$OPTARG";;
        o) FILE="$OPTARG";;
        ?) usage; exit;;
    esac
done
shift $(($OPTIND - 1))

log "DATASIZE: $((DATASIZE*10))MB, TIMEOUT: ${TIMEOUT}min, PIVOT: ${PIVOT}min, FILE:${FILE}, Args: $*"

dd_cmd="dd if=/dev/urandom bs=10485760 count=$DATASIZE"

if [ -z "$2" ]; then
    PORT=$1
    cmd="timeout ${TIMEOUT}m $dd_cmd | nc -l $PORT"
    delta=0
else
    IP=$1
    PORT=$2
    # cmd="timeout ${TIMEOUT}m nc $IP $PORT > /tmp/pktrans_recv.data"
    cmd="timeout ${TIMEOUT}m wget $IP:$PORT -q -O $FILE"
    delta=1
fi

if [ -z "$PORT" ]; then
    usage
    exit
fi

while true
do 
    minute=`date +%M`
    minute=`printf "%d" $minute`
    dt=$((PIVOT-minute%PIVOT+delta))
    if [ $dt -gt 0 ]; then
        log "Sleep for ${dt} min"
        sleep ${dt}m
    fi
    log "Excute: $cmd"
    STIME=`date +%s`
    bash -c "$cmd"
    ETIME=`date +%s`
    DTIME=$((TIMEOUT-(ETIME-STIME)/60))
    if [ $DTIME -gt 0 ]; then
        log "Waiting for $DTIME min"
        sleep ${DTIME}m
    fi
    exitimer
done


