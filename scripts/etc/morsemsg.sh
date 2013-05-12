#/bin/bash 
DOT=.
DASH=-
LOCK="/var/lock/morsemsg"

if [ -f $LOCK ];then
    echo "morse message queue is full"
    exit 1
fi

touch $LOCK

# init led stat
echo 0 > /sys/class/leds/blue\:ph21\:led2/brightness

blink(){
    echo 1 > /sys/class/leds/blue\:ph21\:led2/brightness
    sleep $1
    echo 0 > /sys/class/leds/blue\:ph21\:led2/brightness
    sleep 1
}

CODES=(`/etc/morse-encode.sh $1`)
for CODE in "${CODES[@]}";do
    ATOMS=($(echo $CODE | sed 's/\(.\)/\1 /g'))
    for ATOM in "${ATOMS[@]}";do
        if [ "$ATOM" = $DOT ];then
            #echo "dot"
            blink 0.5
        elif [ "$ATOM" = $DASH ];then
            #echo "dash"
            blink 1
        else
            echo "morse message decode error"
            rm -f $LOCK
            exit 2
        fi
    done
    #echo "end of one letter"
done

rm -f $LOCK
