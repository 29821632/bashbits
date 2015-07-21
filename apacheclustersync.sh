#!/bin/bash

# Sync vhost configs to all members of the cluster, gracefully restart Apache to apply. Ben Bradley 2014. https://github.com/benbradley
# Requires a dedicated apachecluster user with password-less SSH access across the cluster.
# Uses /etc/init.d, not tested with systemd


# Hostname array
declare -a arr=("webhost1.domain.com" "webhost2.domain.com" "webhost2.domain.com" "webhost2.domain.com")


APACHECLUSTERUSR="apachecluster"


# Check local config valid
/etc/init.d/httpd configtest
if [ $? -ne 0 ]; then
	echo "Local httpd configtest failed. Exiting."
	exit 1
fi


# Rsync to each host
echo "rsync vhosts"
for i in "${arr[@]}"
do
	rsync -h --progress --delete /etc/httpd/vhosts.d/* "$APACHECLUSTERUSR@$i:/etc/httpd/vhosts.d/"
	if [ $? -ne 0 ]; then
		echo "rsync to $i failed. Exiting."
		exit 1
	fi
done


# Attempt configtest on each host
echo "httpd configtest"
for i in "${arr[@]}"
do
	echo "$i"
	ssh "$APACHECLUSTERUSR$i" "/etc/init.d/httpd configtest"
	if [ $? -ne 0 ]; then
		echo "httpd configtest $i failed. Exiting."
		exit 1
	fi
done


# Attempt graceful restart on each host
echo "httpd graceful"

