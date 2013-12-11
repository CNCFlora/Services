#!/bin/bash

OPTS=""
[[ $BASE_URL ]] && OPTS="$OPTS -e BASE_URL=$BASE_URL"
[[ $COUCHDB ]] && OPTS="$OPTS -e COUCHDB=$COUCHDB"
[[ $ESEARCH ]] && OPTS="$OPTS -e ESEARCH=$ESEARCH"

docker run -d -p 8181:9292 -p 2424:22 $OPTS -t cncflora/services /root/start.sh

