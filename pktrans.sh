#!/bin/bash
VER=0.2.0

log() {
    echo `date +[%Y-%m-%d_%H:%M:%S]` "($TYPE)" $*
}

exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit
}

usage() {
pn=`basename $0`
printf """pktrans v$VER (C) 2019 xnipse@gmail.com
Usage: $pn [OPTION] [IP] PORT 
Periodically send/receive data to/from a host.

  -h\t print this help.
  -b\t run in background.
  -d\t data size to transfer (k,M,G) [default 100M].
  -t\t transfer timeout (minutes) [default 40].
  -p\t period (minutes) [default 60].
  -s\t start time (0~PERIOD) [default 0].
  -o\t store transfered data to FILE [default /dev/null].
  -O\t log path when running in background [deftaul /tmp/pktrans.log].
  -r\t random start time in each period with a specified SEED.
  -v\t version.

Example:
    Sender: $pn Local_Port
    Reciver: $pn Remote_IP Remote_Port
"""
}

DATASIZE=100M #MB
TIMEOUT=40 #min
PERIOD=60 # 1~60 min
START=0
FILE='/dev/null'
BKG=false
ARGS=`echo "$*" | sed "s/-b//g"`
while getopts 'hd:t:p:s:o:O:r:vb' OPT; do
    case $OPT in
        h) usage; exit;;
        d) DATASIZE="$OPTARG";;
        t) TIMEOUT="$OPTARG";;
        p) PERIOD="$OPTARG";;
        s) START="$OPTARG";;
        o) FILE="$OPTARG";;
        O) LOGFILE="$OPTARG";;
        r) SEED="$OPTARG";;
        b) BKG=true;;
        v) echo "$VER"; exit;;
        ?) usage; exit;;
    esac
done
shift $(($OPTIND - 1))

if $BKG ; then 
    echo 'Run in background ...'
    if [ -z "$LOGFILE" ]; then LOGFILE='/tmp/pktrans.log'; fi
    echo "Redirect output to $LOGFILE"
    # echo "$0 $ARGS"
    nohup bash -c "$0 $ARGS" &> $LOGFILE &
    exit
fi

dd_cmd="dd if=/dev/urandom bs=$DATASIZE count=1"


if [ -z "$2" ]; then
    PORT=$1
    cmd="timeout ${TIMEOUT}m $dd_cmd | nc -l $PORT"
    delta=0
    TYPE='SENDER'
else
    IP=$1
    PORT=$2
    # cmd="timeout ${TIMEOUT}m nc $IP $PORT > /tmp/pktrans_recv.data"
    cmd="timeout ${TIMEOUT}m wget $IP:$PORT -O $FILE -o /dev/stdout|grep saved"
    delta=1
    TYPE='RECEIVER'
fi


if [ -z "$PORT" ]; then
    echo "`basename $0`: missing operand"
    usage
    exit
fi

log "DATASIZE: $DATASIZE, TIMEOUT: ${TIMEOUT}min, PERIOD: ${PERIOD}min, START: ${START}min, Args: $*"
if [ ! -z "$FILE" ]; then log "OUTPUT: $FILE"; fi
if [ ! -z "$SEED" ]; then log "SEED: $SEED"; fi

RANDOM=$SEED

while true; do 
    if [ ! -z "$SEED" ]; then START=$((RANDOM%PERIOD)); fi
    log "START: $START"
    timestamp=`date +%s`
    current=$(( (timestamp/60)%PERIOD ))
    dt=$(( (PERIOD+START-current)%PERIOD+delta ))
    if [ $dt -gt 0 ]; then
        log "Sleep for ${dt} min"
        sleep ${dt}m
    fi
    STIME=`date +%s`
    for i in `seq 2`; do
        log "Excute: $cmd"
        bash -c "$cmd"
        ETIME=`date +%s`
        # if [ $((ETIME-STIME)) -gt 3 ]; then break; else [ $i -eq 2 ] || log 'Retry'; sleep 3; fi
    done
    ETIME=`date +%s`
    DTIME=$((TIMEOUT-(ETIME-STIME)/60))
    if [ $DTIME -gt 0 ]; then
        log "Waiting for $DTIME min"
        sleep ${DTIME}m
    else
        log "Timeout"
    fi
    exitimer
done