#!/bin/bash

OPTS="RACK_ENV=production ENV=production"
[[ $BASE_URL ]] && OPTS="$OPTS BASE_URL=$BASE_URL"
[[ $COUCHDB ]] && OPTS="$OPTS COUCHDB=$COUCHDB"
[[ $ESEARCH ]] && OPTS="$OPTS ESEARCH=$ESEARCH"

#service nginx start
APP_USER=cncflora
su $APP_USER -c "cd ~/www && $OPTS nohup rackup &"

/usr/sbin/sshd -D

