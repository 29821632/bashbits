#!/bin/bash

# Sync vhost configs to all members of the cluster, gracefully restart Apache to apply. Ben Bradley 2014. https://github.com/benbradley
# Requires a dedicated apachecluster user with password-less SSH access across the cluster.
# Uses /etc/init.d, not tested with systemd


APACHECLUSTERUSR="apachecluster"


# Source config file
if [ -f "apacheclustersync_config.sh" ]; then
	source apacheclustersync_config.sh
else
	echo "Config file apacheclustersync_config.sh not found. Exiting."
	exit 1
fi


# Check local config valid
/etc/init.d/httpd configtest
if [ $? -ne 0 ]; then
	echo "Local httpd configtest failed. Exiting."
	exit 1
fi


# Rsync to each host
echo "rsync vhosts"
for i in "${hostsarray[@]}"
do
	rsync -h --progress --delete /etc/httpd/vhosts.d/* "$APACHECLUSTERUSR@$i:/etc/httpd/vhosts.d/"
	if [ $? -ne 0 ]; then
		echo "rsync to $i failed. Exiting."
		exit 1
	fi
done


# Attempt configtest on each host
echo "httpd configtest"
for i in "${hostsarray[@]}"
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