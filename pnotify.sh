#!/bin/bash

# Create an audit report that runs out of cron to notify people when their 
# password is n-days from expiration or when their account is n-days from 
# being locked due to inactivity.  The report should be configurable and 
# increase in notification frequency the closer to the expiration or inactivity date.

# Create a bash script that will:
# Read a list of users from a file – the format of the file will be something like:
# <userid>,<email address>
# Read a configuration file containing global script settings, the config file will have:
# The number of days from expiration when the script will start sending emails
# The number of days of inactivity that will cause the script to start sending emails
# A global list of emails where a summary report will be sent
# A flag indicating whether to send individual user emails (some environments are restricted on what mail can be sent)
# For each user in the list, call “chage -l” to determine when their password will expire – if it is within n-days, send the user an email if possible
# For each user in the list determine how many days they are from being disabled due to inactivity – if within n-days, send the user an email
# Send a summary report to the list of emails in the config file


# Functions
# Check User
# Go through the checks
check_user() {
        local userid=$1
        local email=$2
        echo "Checking userid: $userid"
        days_until_expired=$(( ($(date --date="$(chage -l $userid | grep 'Password expires' | cut -d ":" -f 2)" +%s) - $(date +%s) )/(60*60*24) ))
        if [[ $days_until_expired -lt $PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD && $PNOTIFY_SEND_EMAILS == "true" ]]
	then
        	echo "$userid password expiring"
                notify $email "password expiring in $days_until_expired days on $PNOTIFY_SYSTEM_TYPE"
        fi
}

# Notification
notify() {
	echo "Emailing $1"
        echo "MSG: $2"
        #mail -s "$2" $1 < /dev/null
}

# Check the desired env variables are set
check_env() {
   	env_vars=("PNOTIFY_SYSTEM_TYPE" "PNOTIFY_SEND_EMAILS" "PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD" "PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD")
   	not_set=0
   	for e in ${env_vars[@]}
   	do 
   		if [ "${!e}" == "" ]
      		then
       		 	echo "NO ENV VARIABLE $e"
       	 	        ((not_set=not_set+1))
   		fi
   	done

   	if [ $not_set -gt 0 ]
        then
		exit 99;
        fi
}

########
# Main #
########

# Check env vars
CONFIG_FILE=config_file.env
if [ ! -z $1 ] 
then
	if [ $1 == "loadvars" ]	
	then
		[ ! -f $CONFIG_FILE ] && { echo "$CONFIG_FILE file not found"; exit 99; }
	fi
  
	source $CONFIG_FILE
fi

# Check env variables are loaded
check_env

# Check data file
INPUT=user_data.csv
[ ! -f $INPUT ] && { echo "$INPUT user_data.csv file not found"; exit 99; }

while IFS="," read userid email 
do
        check_user $userid $email
done < $INPUT
