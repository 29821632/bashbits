# Bash Bits
A collection of random bash scripts I've made for all sorts of tasks over the years...

## webalizer_vhosts.sh
Even though it's old, I still find running Webalizer over HTTP log files a decent way of seeing what's going on. Webalizer doesn't play nicely with vhosts by default, needing you to loop over files or setup a webalizer config file for each vhost. This script basically just loops through Apache log files and runs webalizer with a bunch of assumed defaults and some sanity checking.

Status: Unstable - in development

# Who, Where & Why
* Ben Bradley. Systems Engineer, Developer
* London, UK
* Just in case they're useful to the internet

# Returns Policy
No refunds.
These scripts can almost certainly be improved. If you want to send bugfixes in then go ahead, just tell me *why* it should be changed!
I'm not a git pro, I'm not a github pro.