#!/bin/bash

# SVN automator, 'svn add/rm' based on 'svn st' output. Ben Bradley 2013. https://github.com/benbradley
# Grabs the output from 'svn st' and runs 'svn add' or 'svn rm' based on the status codes.
# Useful for merging changes across large directory hierarchies, unborking repos where people have run application auto-updates (CMSs - urgh!)

#SVNST_OUTPUT=`svn st | grep '^?' | awk '{$1="";print;}' | sed 's/^ //'`
SVNST_OUTPUT=`svn st`
if [ $? -ne 0 ]; then
	echo "Unable to 'svn st'"
	exit 1
fi

CWD=$(pwd)

# Initialise counter vars
COUNT_ADD=0
COUNT_RM=0

# Change IFS for loop
IFS_BAK=$IFS
IFS=$'\n'

# Loop through lines of ST_OUTPUT
for LINE in $SVNST_OUTPUT; do

	# Get first char, svn st code
	ST_CODE=${LINE:0:1}
	FILE_PATH=`echo "$LINE" | sed -e 's/^[!?][ ]*//'`
	#echo "$FILE_PATH"

	# Check svn st code
	if [ "$ST_CODE" = "?" ]; then
		# svn add

		# Check file exists
		if [ -f "$FILE_PATH" ] || [ -d "$FILE_PATH" ]; then

			# File/dir found, svn add
			svn add "$FILE_PATH"
			if [ $? -ne 0 ]; then
				echo "svn add '$FILE_PATH' failed. Exiting."
				exit 1
			fi

			# Increment counter
			COUNT_ADD=$((COUNT_ADD+1))

		else
			echo "File not found '$FILE_PATH'. Exiting."
			exit 1
		fi

	elif [ "$ST_CODE" = "!" ]; then
		# svn rm
		svn rm "$FILE_PATH"
		#if [ $? -ne 0 ]; then
		#	echo "svn rm '$FILE_PATH' failed. Already deleted."
		#	exit 1
		#fi

		# Increment counter
		COUNT_RM=$((COUNT_RM+1))

	else
		# Continue loop, next line
		continue
	fi

done

# Revert IFS
IFS=$IFS_BAK
IFS_BAK=

echo "svn add:$COUNT_ADD   svn rm:$COUNT_RM"
echo "_____________________________________"
