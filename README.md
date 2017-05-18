# Bash Bits
A small collection of really random scripts I use on the reg. Whatever.

### apacheclustersync.sh
**Status:** Good to go

### drushbatch.sh
**Status:** Good to go

### ffmpeg_build_el.sh
**Status:** Good to go

### hostnamerandomizer.sh ###
**Status:** Good to go

Including a systemd unit file to run the script on system shutdown.
```shell
sudo cp -v hostnamerandomizer.sh /usr/local/bin/
sudo cp -v hostnamerandomizer.service /etc/systemd/system
sudo systemctl enable hostnamerandomizer && sudo systemctl start hostnamerandomizer && sudo systemctl status hostnamerandomizer
```

### svnauto.sh
**Status:** Good to go

### sysstat_graphite.sh
**Status:** Unstable - in development

### webalizer_vhosts.sh
**Status:** Unstable - in development

# Who, Where & Why
* Ben Bradley. Systems Engineer, Developer
* London, UK
* Just in case they're useful to the internet

# Returns Policy
No refunds.

These scripts can almost certainly be improved. If you want to send bugfixes then go ahead, just tell me *why* it should be changed.
