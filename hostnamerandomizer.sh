#/bin/bash

# Set a random hostname between 3-9 chars.
# Ben Bradley 2016. https://github.com/benbradley
# Using hostnamectl needs further systemd fudging - doing it the old way for now


# GET A RANDOM LENGTH
#RANDLEN=$(grep -m1 -ao '[3-9]' /dev/urandom | sed s/0/10/ | head -n1)
RANDLEN=$(shuf -i 3-9 -n 1)

# GET RANDOM STRING
#RANDHOST=$(pwgen $RANDLEN 1)
RANDHOST=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$RANDLEN" | head -n1)

# GET CURRENT HOSTNAME
CURHOST=$(hostname -f)

# SET HOSTNAME
#HOSTCHANGEOUT=$(hostnamectl set-hostname "$RANDHOST" 2>&1)
HOSTCHANGEOUT=$(hostname "$RANDHOST" 2>&1)

if [ $? -eq 0 ]; then
	# REPLACE IN /etc/hosts
	sed -i "s/$CURHOST/$RANDHOST/g" /etc/hosts
	echo "$RANDHOST" > /etc/hostname
fi

LOGHOSTOUT="Hostname change $CURHOST -> $RANDHOST (system $1)"

echo "$LOGHOSTOUT"
logger -t hostnamerandomizer "$LOGHOSTOUT"
