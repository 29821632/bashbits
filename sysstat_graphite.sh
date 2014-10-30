#!/bin/bash

# Push output of sar into graphite. Ben Bradley 2014. https://github.com/benbradley
# Tracks the time string of the last sysstat collection in TIME_FILE to filter the sar output
# Just add a function for each sar command you want to run and do all text processing within that function.

# Time file
TIME_FILE="/tmp/sysstat_graphite_lasttime.txt"

# Getopts
while getopts ":g:" opt; do
	case $opt in 
		g)
			graphite_url=$OPTARG
			;;
		\?)
		echo "Invalid option -$OPTARG" >&2
		exit 1
		;;
	esac
done


HOSTNAME=`hostname --short`
STATS_PREFIX="sysstat.$HOSTNAME"
NOW=`date +%s`


# Create time file
if [ ! -f "$TIME_FILE" ]; then

	touch "$TIME_FILE"
	
	OUT=$?
	if [ $OUT -ne 0 ]; then
		echo "Could not create '$TIME_FILE'. Exiting."
		exit 1
	fi
fi


# Read in last time
TIME_LAST=`cat "$TIME_FILE"`


# Run sar to get most recent stat time
TIME_NOW=`sar | grep -iv average | tail -n1 | awk {'print $1'}`


# Sar IO command
function sar_io {
	TYPE='io'
	DATA=''

	# Run sar
	OUTPUT=`sar -p -d | grep -iv average | grep "$TIME_NOW" | tail -n20`

	RETURN=$?
	if [ $RETURN -ne 0 ]; then
		echo "Command $TYPE failed. Exiting."
		exit 1
	fi

	# Loop through lines of OUTPUT
	while read -r line
	do

		UTIL_PCT=${line##* }
		echo $UTIL_PCT
		#echo printf("%s", $STATS_PREFIX)
		#DATA="$DATA"
	done < <(OUTPUT)

}


# Compare times
if [ "$TIME_LAST" == "$TIME_NOW" ]; then
	# Same time, exit
	exit 0
else
	#echo "$TIME_NOW" > "$TIME_FILE"
	# Run sar functions
	sar_io
fi


# Push to graphite
#echo "sysstat.${HOSTNAME}.tmp.file.count ${MY_DATA} ${NOW}" | nc $graphite_url

