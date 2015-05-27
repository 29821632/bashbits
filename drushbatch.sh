#!/bin/bash

# Run drush commands on all Drupal sites within an Aegir platform. Ben Bradley 2014. https://github.com/benbradley
# Usage: ./drushbatch.sh -d /var/aegir/platforms/<platform_name>/sites -c "cc all" -x

TIMER_START=$SECONDS

# Check for drush
command -v drush >/dev/null
OUT=$?
if [ $OUT -ne 0 ]; then
	echo "Command 'drush' not found. Ensure drush is installed for this user."
	exit 1
fi

OPTIND=1 # Reset if getopts used previously

# No options
if (($# == 0)); then
	echo "Usage: drushbatch.sh -d site_dir -c command [-x]"
	exit 2
fi

# Parse options
while getopts ":d:c:x" opt; do
	case "$opt" in

		d)
			if [ ! -z "$SITES_DIR" ]; then
				echo "-d already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Sites directory starts with option string."
				exit 2
			fi
			SITES_DIR="$OPTARG"
			;;

		c)
			if [ ! -z "$DRUSH_CMD" ]; then
				echo "-c already set."
				exit 2
			fi
			if [ z"${OPTARG:0:1}" == "z-" ]; then
				echo "Drush command starts with option string."
				exit 2
			fi
			DRUSH_CMD="$OPTARG"
			;;

		x)
			if [ ! -z "$DRUSH_EXEC" ]; then
				echo "-x already set."
				exit 2
			fi
			DRUSH_EXEC=1
			;;

		\?)
			echo "Invalid option: $OPTARG" >&2
			exit 2;;
		#:)
		#	echo "Option -$opt requires an argument" >&2
		#	exit 2;;
	esac
done
shift $((OPTIND-1))

# Check for site directory
if [ ! -d "$SITES_DIR" ]; then
	echo "Sites directory '$SITES_DIR' does not exist. Exiting."
	exit 1
fi

# Check DRUSH_CMD
if [ ! "$DRUSH_CMD" ]; then
	echo "Drush command not specified."
	exit 1
fi

# Drush exec notice
if [ ! $DRUSH_EXEC ]; then
	echo "#     INFO: Dry run mode. Add -x to execute"
fi

# Find valid Aegir sites, look for settings.php file
cd "$SITES_DIR"
SITES=`find -L . -mindepth 2 -maxdepth 2 -type f -name settings.php | sed "s@./\([a-z0-9_\.\-]\{1,\}\)/.*@\1@g" | sort`

OUT=$?
if [ $OUT -ne 0 ]; then
	echo "Error running find command. Exiting."
	exit 1
fi

if [ -z "$SITES" ]; then
	echo "No sites found. Exiting."
	exit 1
fi

echo ""

# Init counters
COUNT_SITES=0
COUNT_OK=0
COUNT_FAILED=0

# Loop through lines of SITES
while IFS= read -r LINE
do

	COUNT_SITES=$((COUNT_SITES+1))
	SITE="$LINE"
	echo "Site: $SITE"

	# Check site dir is valid
	if [ ! -d "$SITE" ]; then
		echo "Site '$SITE' is not a valid directory. Exiting."
		exit 1
	fi

	echo "drush $SITE $DRUSH_CMD"

	# Execute?
	if [ $DRUSH_EXEC ]; then
		# Execute!
		drush "$SITE" $DRUSH_CMD

		OUT=$?
		if [ $OUT -eq 0 ]; then
			COUNT_OK=$((COUNT_OK+1))
		else
			COUNT_FAILED=$((COUNT_FAILED+1))
			#continue
		fi
	fi

	echo ""

done <<< "$SITES"

# Stop timer
SCRIPT_DURATION=$(( SECONDS - TIMER_START ))

echo "Sites:$COUNT_SITES  OK:$COUNT_OK  Fail:$COUNT_FAILED  Duration:$SCRIPT_DURATION secs"
echo ""
