#!/bin/bash
set -e
set -u
set -o pipefail

calcDelay=85 #in ms
unit=1
unitMarking="B"
interface=":"
formatValue=""
interval=1
count=1
infinite=0

help () {
cat << EOF
A bash script for monitoring bandwidth usage.

usage: $(basename $0) [-b bits] [-c count] [-f <k, M, G> prefix ]
 		   [-i <seconds> interval] [-I <interface name> interface]
example:
	./netspeed.sh -f k		      	   #speed in kB/s on all interfaces
	./netspeed.sh -b -f M -c 0 -I eth0 -i 2    #speed in Mb/s every 2 seconds until user-interrupt for eth0
EOF
}

while getopts 'bBf:I:i:c:h' OPTION; do
  case "$OPTION" in
    b)
      unit=8
      unitMarking="b"
      ;;
    B)
      unit=1
      unitMarking="B"
      ;;

    f)
      formatValue="$OPTARG"
      ;;

    I)
      interface="$OPTARG"
      ;;

    i)
      interval="$OPTARG"
      
      ;;

    c)
      count="$OPTARG"
      if (( count == 0));then
          infinite=1
      fi
      ;;

    h)
	help
	exit 1
	;;
    ?)
      #echo "script usage: $(basename $0) [-I <interface>]" >&2
      echo "see '$(basename $0) -h' for help"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

fullCalcDelay=$((interval * 1000 + calcDelay))
echo $interval
getCurrentBytes () {
    N=0
    for i in $(awk '/:/ { print($1, $2, $10) }' < /proc/net/dev | grep "${1}")
    do
      initBytes[$N]="$i"
      let "N= $N + 1"
    done
}

printValue () {
    getCurrentBytes $3
    initRX=0
    initTX=0
    N=0
    for i in "${initBytes[@]}"
    do
        if [[ $(( N % 3 )) == 1 ]]
        then
	          initRX=$((${initRX} + ${i}))
        elif [[ $(( N % 3 )) == 2 ]]
        then
	          initTX=$((${initTX} + ${i}))
        fi
        let "N= $N + 1"
    done

    sleep ${4}

    finalRX=0
    finalTX=0
    getCurrentBytes $3
    N=0
    for i in "${initBytes[@]}"
    do
        if [[ $(( N % 3 )) == 1 ]]
        then
	          finalRX=$((${finalRX} + ${i}))
        elif [[ $(( N % 3 )) == 2 ]]
        then
	          finalTX=$((${finalTX} + ${i}))
        fi
        let "N= $N + 1"
    done

    downloadSpeed=$(( ($finalRX - $initRX) * ${1}))
    downloadSpeed=`echo ${downloadSpeed} ${2} ${4} 1000 ${5} | awk '{printf "%.2f \n", $1/$2/$5*($3*$4)}'`
    uploadSpeed=$(( ($finalTX - $initTX) * ${1}))
    uploadSpeed=`echo ${uploadSpeed} ${2} ${4} 1000 ${5} | awk '{printf "%.2f \n", $1/$2/$5*($3*$4)}'`
    echo "${downloadSpeed}   ${uploadSpeed}"
}

if [[ $formatValue == "k" || $formatValue == "K" ]]
then
    format=1000
    formatValue="k"
elif [[ $formatValue == "M" || $formatValue == "m" ]]
then
    format=1000000
    formatValue="M"
elif [[ $formatValue == "G" || $formatValue == "g" ]]
then
    format=10000000000
    formatValue="G"
else
    format=1
    formatValue=""
fi


echo	"download upload [${formatValue}${unitMarking}/s]"
h=0
while (( h < count || infinite == 1 ))
do
    printValue $unit $format $interface $interval $fullCalcDelay
    ((h+=1))
done

exit 0
