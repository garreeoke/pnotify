FROM centos:8

WORKDIR /pnotify
COPY pnotify.sh /pnotify/
CMD ["/pnotify/pnotify.sh"]
