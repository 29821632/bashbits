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
echo "* httpd configtest local"
/etc/init.d/httpd configtest
if [ $? -ne 0 ]; then
	echo "httpd configtest local failed. Exiting."
	exit 1
fi
echo ""


# Rsync to each host
for i in "${hostsarray[@]}"
do
	echo "* rsync vhosts $i"
	rsync -rh --delete /etc/httpd/vhosts.d/ "$APACHECLUSTERUSR@$i:/etc/httpd/vhosts.d"
	if [ $? -ne 0 ]; then
		echo "rsync to $i failed. Exiting."
		exit 1
	fi
	echo ""
done


# Attempt configtest on each host
for i in "${hostsarray[@]}"
do
	echo "* httpd configtest $i"
	ssh "$APACHECLUSTERUSR@$i" "sudo /etc/init.d/httpd configtest"
	if [ $? -ne 0 ]; then
		echo "httpd configtest $i failed. Exiting."
		exit 1
	fi
	echo ""
done


# Attempt graceful restart on each host
for i in "${hostsarray[@]}"
do
	echo "* httpd graceful $i"
	ssh "$APACHECLUSTERUSR@$i" "sudo /etc/init.d/httpd graceful"
	if [ $? -ne 0 ]; then
		echo "httpd graceful $i failed. Exiting."
		exit 1
	fi
	echo ""
done


# Graceful restart on local host
echo "* httpd graceful local"
/etc/init.d/httpd graceful
if [ $? -ne 0 ]; then
	echo "httpd graceful local failed. Exiting."
	exit 1
fi
echo ""