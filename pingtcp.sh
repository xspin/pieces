#!/bin/bash
exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit
}

usage() {
    printf """Usage: `basename $0` [OPTION] [DEST] [PORT]
Collect the data of pinging a host via tcp or icmp.
  -h\t print this help.
  -i\t time interval (sec) [default 60].
  -b\t run in background.
  -o\t output path when running in background [deftaul log_pingtcp.csv].
  -p\t TCP or ICMP ping [default TCP]
"""
}

PROTOCOL='tcp'
INTERVAL=60
OUTPUT='log_pingtcp.csv'
BKG=false
ARGS="$*"
while getopts 'hi:bo:fp:' OPT; do
    case $OPT in
        h) usage; exit;;
        i) INTERVAL="$OPTARG";;
        o) OUTPUT="$OPTARG";;
        b) BKG=true;;
        f) FLAG='run';;
        p) PROTOCOL="$OPTARG";;
        ?) usage; exit;;
    esac
done
shift $(($OPTIND - 1))

if [ -z "$1" ]; then usage;exit; fi

if  ! $BKG ; then 
    OUTPUT='/dev/stdout'; 
elif [ -z "$FLAG" ]; then
    echo 'Run in background ...'
    # echo "Save data to $OUTPUT"
    # echo "Excute: $0 -f $ARGS"
    LOGFILE='/tmp/pingtcp.log'
    echo "Redirect output to $LOGFILE"
    nohup bash -c "$0 -f $ARGS" &>$LOGFILE &
    sleep 1
    tail $LOGFILE
    exit
fi

case "${PROTOCOL,,}" in 
    'tcp')
        HEADER="timestamp,loss,avg,min,max"
        if [ -z "$2" ]; then
            PORT=$1
            TYPE='SERVER'
        else
            HOST=$1
            PORT=$2
            TYPE='CLIENT'
        fi
        ;;
    'icmp')
        HEADER="timestamp,loss,avg,min,max,dev"
        HOST=$1
        TYPE='CLIENT'
        ;;
    *)
        echo "Wrong arg: -p $PROTOCOL" >&2
        exit
        ;;
esac

COUNT=10
TCPINGCMD="paping --nocolor -c $COUNT -p $PORT $HOST"
ICMPINGCMD="ping -c $COUNT $HOST"

stat(){
    if [ "${PROTOCOL,,}" = "tcp" ]; then
        # loss avg min max 
        RAW=`$TCPINGCMD|tail -n 4|sed -e 's/[()%:=,a-zA-Z]//g'` 
        DATA=`echo $RAW|awk 'BEGIN{OFS=","} {print $4,$7,$5,$6}'`
    elif [ "${PROTOCOL,,}" = "icmp" ]; then
        # loss avg min max mdev
        RAW=`$ICMPINGCMD|tail -n 2|sed -e 's/[%=,a-z]//g' -e 's/\// /g'`
        DATA=`echo $RAW|awk 'BEGIN{OFS=","} {print $3,$6,$5,$7,$8}'`
    fi
    echo `date +'%Y-%m-%d %H:%M:%S'`,$DATA
}

case $TYPE in
    'SERVER')
        echo "Listening on $PORT ... "
        nc -lk $PORT
        ;;
    'CLIENT')
        echo "Start $PROTOCOL pinging to $HOST:$PORT ..."
        echo $HEADER >> $OUTPUT
        while true; do
            stat >> $OUTPUT
            sleep $INTERVAL
            exitimer
        done
esac