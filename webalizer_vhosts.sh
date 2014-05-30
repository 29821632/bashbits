#!/bin/bash

# Webalizer vhost processor
# Ben Bradley 2013 https://github.com/benbradley
#
# Loop through Apache vhost configs and run webalizer on the access logs
# Reads ServerName directive(s) from vhost configuration files
# Assumes vhost-specific logging with log file names starts with ServerName and ends with $suffix
#
# http://www.webalizer.org/webalizer.1.html
#
# Options:
# - vhost config dir
# - output dir
# - log root dir = /var/log/httpd
# - log file suffix = _access.log
# - passthrough options
#
# Webalizer options
# -T
# -p
# -c webalizer.conf
# -n hostname
# -o output dir

TIMER_START=$SECONDS

# Webalizer command exists?
: 'command -v webalizer >/dev/null
OUT=$?
if [ $OUT -ne 0 ]; then
	echo "Webalizer not found or is not in PATH"
	exit 1
fi
'
OPTIND=1 # Reset if getopts used previously

# No options
if (($# == 0)); then
	echo "Usage: webalizer-vhosts.sh -l /var/log/httpd -o /var/www/html/webstats -v /etc/httpd/vhosts.d [-s _access.log]"
	exit 2
fi

# Parse options
while getopts ":l:o:v:s" opt; do
	case "$opt" in

		l)
			if [ ! -z "$LOG_DIR" ]; then
				echo "Log directory already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Log directory starts with option string."
				exit 2
			fi
			LOG_DIR=$OPTARG
			;;

		o)
			if [ ! -z "$OUTPUT_DIR" ]; then
				echo "Output directory already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Output directory starts with option string."
				exit 2
			fi
			OUTPUT_DIR=$OPTARG
			;;

		s)
			if [ ! -z "$LOG_SUFFIX" ]; then
				echo "Log file suffix already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Log file suffix starts with option string."
				exit 2
			fi
			LOG_SUFFIX=$OPTARG
			;;

		v)
			if [ ! -z "$VHOST_DIR" ]; then
				echo "Vhost config directory already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Vhost config directory starts with option string."
				exit 2
			fi
			VHOST_DIR=$OPTARG
			;;

		\?)
			echo "Invalid option: $OPTARG" >&2
			exit 2;;
	esac
done


# Check LOG_DIR
if [ ! "$LOG_DIR" ]; then
	echo "Log directory not specified."
	exit 1
fi

# Check OUTPUT_DIR
if [ ! "$OUTPUT_DIR" ]; then
	echo "Output directory not specified."
	exit 1
fi

# Check VHOST_DIR
if [ ! "$VHOST_DIR" ]; then
	echo "Vhost config directory not specified."
	exit 1
fi

# Normalise trailing slash in LOG_DIR
LOG_DIR=${LOG_DIR%/}
LOG_DIR="$LOG_DIR/"

# Normalise trailing slash in OUTPUT_DIR
OUTPUT_DIR=${OUTPUT_DIR%/}
OUTPUT_DIR="$OUTPUT_DIR/"

# Normalise trailing slash in VHOST_DIR
VHOST_DIR=${VHOST_DIR%/}
VHOST_DIR="$VHOST_DIR/"

# Check LOG_DIR exists
if [ ! -d "$LOG_DIR" ]; then
	echo "Log directory '$LOG_DIR' does not exist."
	exit 1
fi

# Check OUTPUT_DIR exists/writeable
if [ ! -d "$OUTPUT_DIR" ] || [ ! -w "$OUTPUT_DIR" ]; then
	echo "Output directory '$OUTPUT_DIR' does not exist or is not writeable."
	exit 1
fi

# Check VHOST_DIR exists
if [ ! -d "$VHOST_DIR" ]; then
	echo "Vhost config directory '$VHOST_DIR' does not exist."
	exit 1
fi

# Output time/date
echo "webalizer-vhosts.sh $(date)"

# Initialise counter vars
COUNT_OK=0
COUNT_VHOSTS=0

# Change IFS for loop
IFS_BAK=$IFS
IFS=$'\n'

# Grep vhost directory
GREP_OUTPUT=`grep -h "ServerName \+" "$VHOST_DIR"*`
if [ $? -ne 0 ]; then
	echo "Grep of vhost directory failed. Exiting."
	exit 1
fi

# Loop through lines of GREP_OUTPUT
for LINE in $GREP_OUTPUT; do

	COUNT_VHOSTS=$((COUNT_VHOSTS+1))

	VHOST_DOMAIN=`echo "$LINE" | sed -e 's/^ *ServerName \+//' -e 's/ *$//'`
	echo "* $VHOST_DOMAIN"

	# Check vhost stats output dir exists/writeable
	OUTPUT_DIR_VHOST="$OUTPUT_DIR$VHOST_DOMAIN"
	#echo "$OUTPUT_DIR_VHOST"

	# Build LOG_FILE full path
	LOG_FILE="$LOG_DIR$VHOST_DOMAIN$LOG_SUFFIX"

	if [ -f "$LOG_FILE" ]; then
		# Log file exists - DO IT!


	else
		echo "Log file '$LOG_FILE' is not a valid file. Exiting."
		exit 1
	fi

	# Check OUTPUT_DIR_VHOST dir exists/writeable
	if [ ! -d "$OUTPUT_DIR_VHOST" ]; then

		# Dir doesn't exist, attempt create
		echo "Create output directory '$OUTPUT_DIR_VHOST'"
		mkdir -p "$OUTPUT_DIR_VHOST"
		OUT=$?

		if [ $OUT -ne 0 ] || [ ! -d "$OUTPUT_DIR_VHOST" ] || [ ! -w "$OUTPUT_DIR_VHOST" ]; then
			echo "Could not create directory '$OUTPUT_DIR_VHOST'. Exiting."
			exit 1
		fi

	elif [ ! -w "$OUTPUT_DIR_VHOST" ]; then
		echo "Output directory '$OUTPUT_DIR_VHOST' is not writeable. Exiting."
		exit 1
	fi

	# Final OUTPUT_DIR_VHOST check
	if [ ! -d "$OUTPUT_DIR_VHOST" ] || [ ! -w "$OUTPUT_DIR_VHOST" ]; then
		echo "Output directory '$OUTPUT_DIR_VHOST' does not exist or is not writeable. Exiting."
		exit 1
	else
		# Directory OK

	fi
done

# Stop timer
SCRIPT_DURATION=$(( SECONDS - TIMER_START ))

echo ""
echo "Vhosts:$COUNT_VHOSTS   OK:$COUNT_OK   Duration:$SCRIPT_DURATION secs"
echo "__________________________________________"

# Revert IFS
IFS=$IFS_BAK
IFS_BAK=