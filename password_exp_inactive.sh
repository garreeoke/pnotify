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

# Global vars
emails_sent=()
summary_file="pnotify_summary_$(date +%m-%d-%Y).txt"

#Functions

print_usage() {
	echo "Options: "
        echo ""
	echo "-c [PNOTIFY_CFG_FILE]"
	echo "-d [PNOTIFY_DATA_FILE]"
	echo "-e [PNOTIFY_PASSWORD_EXPIRE_DAYS]"
	echo "-i [PNOTIFY_PASSWORD_INACTIVE_DAYS]"
	echo "-o [PNOTIFY_OUTPUT_DIR]"
	echo "-r [PNOTIFY_REPORT_EMAILS]"
	echo "-s [PNOTIFY_SEND_EMAILS]"
	echo ""
}

check_user() {
        local userid=$1
        local email=$2
        echo "Checking userid: $userid"
	# Make sure user exists
        if id -u $userid >/dev/null 2>&1; then
		# EXPIRED
                days_until_expired=$(( ($(date --date="$(chage -l $userid | grep 'Password expires' | cut -d ":" -f 2)" +%s) - $(date +%s) )/(60*60*24) ))
                echo "days_until_expired: $days_until_expired"
                if [[ $days_until_expired -lt $PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD && $PNOTIFY_SEND_EMAILS == "true" ]]
                then
                        echo "$userid password expiring sending email to $email"
                        send_email user "Password expiriation warning" $email "$userid Password expiring in $days_until_expired days on $(hostname)"
                fi
		# INACTIVE
		days_inactive=$(( ($(date --date="$(chage -l $userid | grep 'Password inactive' | cut -d ":" -f 2)" +%s) - $(date +%s) )/(60*60*24) ))
                echo "days_until_inactive: $days_inactive"
                if [[ $days_inactive -lt $PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD && $PNOTIFY_SEND_EMAILS == "true" ]]
                then
                        echo "$userid password inactivity warning sending email to $email"
                        send_email user "Inactivity warning" $email "$userid Password will expire due to inactivity in $days_inactive days on $(hostname)"
                fi
        else 
		echo "Users does not exist"
        fi
}

# Send Email
send_email() {
	TYPE=$1
	SUBJECT=$2
	RECEIVER=$3
        TEXT=$4
	SENDER=$(whoami)

	echo "Sending $TYPE email to $RECEIVER"
	if [[ $TYPE == "user" ]] 
	then
		msgsummary="Subject: $SUBJECT --- From: $SENDER --- To: $RECEIVER --- $TEXT"
		echo $msgsummary >> $PNOTIFY_OUTPUT_DIR/$summary_file
        	emails_sent+=( $msgsummary ) 
		# Below should send if mail configured on server
		echo -e $TEXT  | mailx -s "$SUBJECT" $RECEIVER
		# Example if setup gmail account in ~/.mailrc
		#echo -e $TEXT  | mailx -A gmail -s "$SUBJECT" $RECEIVER
	elif [[ $TYPE == "summary" ]]
	then
		msg="Subject: $SUBJECT\nFrom: $SENDER\nTo: $RECEIVER\n\n"
		mailx -A gmail -s "$SUBJECT" $RECEIVER < $PNOTIFY_OUTPUT_DIR/$summary_file
	fi
}

# Send summary
send_summary() {
	echo "Checking if need to send summary report"
	if [ ${#PNOTIFY_REPORT_EMAILS[@]} -gt 0 ]
        then
                # Build file for the attachment to the email
		local summary_email_list=$(printf '%s\n' "$(local IFS=,; printf '%s' "${PNOTIFY_REPORT_EMAILS[*]}")")
		send_email summary "Pnotify notification summary" $summary_email_list k
        fi
}

# Check the desired env variables are set
check_env() {
        env_vars=()
        if [ ! -z $1 ]
	then
		env_vars+=( $1 )	
	else
		env_vars=("PNOTIFY_SEND_EMAILS" "PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD" "PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD" "PNOTIFY_DATA_FILE")
	fi
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
		print_usage
		exit 99;
        fi
}

########
# Main #
########

# Process args
while getopts 'c:d:e:i:o:r:st:' flag; do
  case "${flag}" in
    c) PNOTIFY_CFG_FILE="${OPTARG}" ;;
    d) PNOTIFY_DATA_FILE="${OPTARG}" ;;
    e) PNOTIFY_PASSWORD_EXPIRE_DAYS="${OPTARG}" ;;
    i) PNOTIFY_PASSWORD_INACTIVE_DAYS="${OPTARG}" ;;
    o) PNOTIFY_OUTPUT_DIR="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

# First check if PNOTIFY_CFG_FILE is set, if so load the file
# Can specify with -c option on command line or preset ENV variable
# If -c option is not passed assume all ENV variables are set (most useful for docker)
if [ ! -z $PNOTIFY_CFG_FILE ]
then
        [ ! -f $PNOTIFY_CFG_FILE ] && { echo "$PNOTIFY_CFG_FILE file not found"; exit 99; }
	source $PNOTIFY_CFG_FILE
fi

# Check all needed env variables are loaded
check_env

# Check data file
[ ! -f $PNOTIFY_DATA_FILE ] && { echo "$PNOTIFY_DATA_FILE file not found"; exit 99; }

# Read user list and get details
while IFS="," read userid email 
do
        check_user $userid $email
done < $PNOTIFY_DATA_FILE

# Send summary email
if [ ${#emails_sent[@]} -gt 0 ]
then
  	send_summary 
fi
