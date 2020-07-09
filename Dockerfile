FROM centos:8

# Uncomment and set if want to bake in to image
#ENV PNOTIFY_DATA_FILE data/user_data.csv
#ENV PNOTIFY_PASSWORD_EXPIRE_DAYS_THRESHOLD 900
#ENV PNOTIFY_PASSWORD_INACTIVE_DAYS_THRESHOLD 900
#ENV PNOTIFY_OUTPUT_DIR reports
#ENV PNOTIFY_REPORT_EMAILS garreesett@gmail.com
#ENV PNOTIFY_SEND_EMAILS true
#ENV PNOTIFY_SYSTEM_TYPE "VPN system"

WORKDIR /pnotify
COPY password_exp_inactive.sh /pnotify/

# Make reports directory
RUN mkdir reports

CMD ["/pnotify/password_exp_inactive.sh.sh"]
