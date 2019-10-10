#!/bin/bash
# Ver 0.1.1

log() {
    echo `date +[%Y-%m-%d_%H:%M:%S]` "($TYPE)" $*
}

exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit
}

usage() {
pn=`basename $0`
printf """Usage: $pn [OPTION] [IP] PORT 
Periodically send/receive data to/from a host.

  -h\t print this help.
  -d\t [default 200] data size to transfer (MB).
  -t\t [default 40] transfer timeout (minutes).
  -p\t [default 60] period (minutes)
  -s\t [default 0] start time (0~PERIOD).
  -o\t [default /dev/null] store data to FILE.
  -r\t random start time in each period with a specified SEED.

Example:
    Sender: $pn Local_Port
    Reciver: $pn Remote_IP Remote_Port
"""
}

DATASIZE=200 #MB
TIMEOUT=40 #min
PERIOD=60 # 1~60 min
START=0
FILE='/dev/null'

while getopts 'hd:t:p:s:o:r:' OPT; do
    case $OPT in
        h) usage; exit;;
        d) DATASIZE="$OPTARG";;
        t) TIMEOUT="$OPTARG";;
        p) PERIOD="$OPTARG";;
        s) START="$OPTARG";;
        o) FILE="$OPTARG";;
        r) SEED="$OPTARG";;
        ?) usage; exit;;
    esac
done
shift $(($OPTIND - 1))


dd_cmd="dd if=/dev/urandom bs=10M count=$((DATASIZE/10))"

if [ -z "$2" ]; then
    PORT=$1
    cmd="timeout ${TIMEOUT}m $dd_cmd | nc -l $PORT"
    delta=0
    TYPE='SENDER'
else
    IP=$1
    PORT=$2
    # cmd="timeout ${TIMEOUT}m nc $IP $PORT > /tmp/pktrans_recv.data"
    cmd="timeout ${TIMEOUT}m wget $IP:$PORT -q -O $FILE -o /dev/null"
    delta=1
    TYPE='RECEIVER'
fi


if [ -z "$PORT" ]; then
    echo "`basename $0`: missing operand"
    usage
    exit
fi

log "DATASIZE: $((DATASIZE))MB, TIMEOUT: ${TIMEOUT}min, PERIOD: ${PERIOD}min, START: ${START}min, Args: $*"
if [ ! -z "$FILE" ]; then log "OUTPUT: $FILE"; fi
if [ ! -z "$SEED" ]; then log "SEED: $SEED"; fi

RANDOM=$SEED

while true; do 
    if [ ! -z "$SEED" ]; then START=$((RANDOM%PERIOD)); fi
    timestamp=`date +%s`
    current=$(( (timestamp/60)%PERIOD ))
    dt=$(( (PERIOD+START-current)%PERIOD+delta ))
    if [ $dt -gt 0 ]; then
        log "Sleep for ${dt} min"
        sleep ${dt}m
    fi
    for i in `seq 2`; do
        log "Excute: $cmd"
        STIME=`date +%s`
        bash -c "$cmd"
        ETIME=`date +%s`
        DTIME=$((TIMEOUT-(ETIME-STIME)/60))
        if [ $DTIME -ge 1 ]; then break; else [ $i -eq 2 ] || log 'Retry'; fi
    done
    if [ $DTIME -gt 0 ]; then
        log "Waiting for $DTIME min"
        sleep ${DTIME}m
    fi
    exitimer
done