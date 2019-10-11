#!/bin/bash
exitimer() {
    [ `date +%Y%m%d` -lt 20191031 ] || exit
}

usage() {
    printf """Usage: `basename $0` [OPTION] [DEST] [PORT]
Collect the data of pinging a tcp port.
  -h\t print this help.
  -i\t time interval (sec) [default 60].
  -b\t run in background.
  -o\t output path when running in background [deftaul pingtcp_log.csv].
"""
}

INTERVAL=60
OUTPUT='pingtcp_log.csv'
BKG=false
ARGS="$*"
while getopts 'hi:bf' OPT; do
    case $OPT in
        h) usage; exit;;
        i) INTERVAL="$OPTARG";;
        o) OUTPUT="$OPTARG";;
        b) BKG=true;;
        f) FLAG='run';;
        ?) usage; exit;;
    esac
done
shift $(($OPTIND - 1))

if  ! $BKG ; then 
    OUTPUT='/dev/stdout'; 
elif [ -z "$FLAG" ]; then
    echo 'Run in background ...'
    # echo "Save data to $OUTPUT"
    # echo "Excute: $0 -f $ARGS"
    LOGFILE='/tmp/pingtcp.log'
    echo "Redirect output to $LOGFILE"
    nohup bash -c "$0 -f $ARGS" &>$LOGFILE &
    tail $LOGFILE
    exit
fi

if [ -z "$2" ]; then
    PORT=$1
    TYPE='SERVER'
else
    HOST=$1
    PORT=$2
    TYPE='CLIENT'
fi
if [ -z "$PORT" ]; then usage;exit; fi

TCPING=paping
TCPINGCMD="$TCPING --nocolor -c 10 -p $PORT $HOST"

stat(){
    RAW=`$TCPINGCMD|tail -n 4|grep =|sed -e 's/[=,()ms%]//g'`
    DATA=`echo $RAW | awk 'BEGIN{OFS=","} {print $7,$9,$11,$13}'`
    echo `date +'%Y-%m-%d %H:%M:%S'`,$DATA
}

main() {
    case $TYPE in
        'SERVER')
            echo "Listening on $PORT ... "
            nc -lk $PORT
            ;;
        'CLIENT')
            echo "Start TCP pinging to $HOST:$PORT ..."
            echo "timestamp, fail, min, max, avg" >> $OUTPUT
            while true; do
                stat >> $OUTPUT
                sleep $INTERVAL
                exitimer
            done
    esac
}

main