#!/bin/bash
set -e
set -u
set -o pipefail

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

getCurrentBytes () {
    initBytes=()
    while IFS= read -r line; do
        initBytes+=( "$line" )
    done < <( awk '/:/ { print($1, $2, $10) }' < /proc/net/dev | grep "${1}" )

}

printValue () {
    getCurrentBytes $3
    initRX=0
    initTX=0
    for i in "${initBytes[@]}"
    do
        deviceBytes=($i)
	initRX=$((${initRX} + ${deviceBytes[1]}))
	initTX=$((${initTX} + ${deviceBytes[2]}))
    done

    sleep ${4}

    finalRX=0
    finalTX=0
    getCurrentBytes $3
    for i in "${initBytes[@]}"
    do
        deviceBytes=($i)
        finalRX=$((${finalRX} + ${deviceBytes[1]}))
        finalTX=$((${finalTX} + ${deviceBytes[2]}))
    done
    downloadSpeed=$(( ($finalRX - $initRX) * ${1}))
    downloadSpeed=`echo ${downloadSpeed} ${2} ${4} | awk '{printf "%.2f \n", $1/$2/$3}'`
    uploadSpeed=$(( ($finalTX - $initTX) * ${1}))
    uploadSpeed=`echo ${uploadSpeed} ${2} ${4} | awk '{printf "%.2f \n", $1/$2/$3}'`
    echo "${downloadSpeed}	${uploadSpeed}"
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
    printValue $unit $format $interface $interval
    ((h+=1))
done

exit 0
