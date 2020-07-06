# PNOTIFY

Script to check logins for upcoming password expiration and inactivity.

## Quick Start

**Currently emails are not being sent ... that work is TBD**

1. Clone this repo
2. Modify data/user_data.csv to modify user list
3. Modify config_file.env
4. Run: pnotify -c data/config_file.env

## Syntax

`pnotify [options]

-c [PNOTIFY_CFG_FILE]
-d [PNOTIFY_DATA_FILE]
-e [PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD]
-i [PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD]
-o [PNOTIFY_OUTPUT_DIR]
-r [PNOTIFY_REPORT_EMAILS]
-s [PNOTIFY_SEND_EMAILS]
-t [PNOTIFY_SYSTEM_TYPE]`

If -c is used or PNOTIFY_CFG_FILE is set, all options will be loaded from a config file.  
If in both places, config file wins.

## ENV Variables

Optionally set this env variables to be able to run without options.  Good for running with
docker

* PNOTIFY_CFG_FILE: config file
* PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD: number of days until expiration to send email to the user
* PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD: number of days inactive to start sending emails
* PNOTIFY_SYSTEM_TYPE: type of system this is running on (ie. VPN)
* PNOTIFY_SEND_EMAILS: true or false whether to send emails or not
* PNOTIFY_REPORT_EMAILS: list of email addresses to send summary report email
* PNOTIFY_DATA_FILE: relative path to input file
* PNOTIFY_OUTPUT_DIR: directory for summary report

## Docker 

Use a docker container to run

1. Clone this repo
2. Modify Dockerfile to include ENV variables and build image
3. Run image.  
    * If ENV variables are not specified in the dockerfile, must specify on docker run comandline
    * Any required volume mounts will are to be specified at docker runtime
    
## Examples
* Command line with cfg file: pnotify -c data/config_file.env
* Docker mounting volume running image: docker run -v "$(pwd)"/data:/pnotify/data garreeoke/pnotify "./pnotify.sh" -c data/config_file.env
* Docker file passing env var: docker run --env "PNOTIFY_CFG_FILE=/pnotify/data/config_file.env" -v "$(pwd)"/data:/pnotify/data garreeoke/pnotify "./pnotify.sh"