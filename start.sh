#!/bin/bash

#service nginx start
APP_USER=cncflora
su $APP_USER -c 'cd ~/www && CONFIG=/root/config.yml RACK_ENV=production nohup rackup &'

/usr/sbin/sshd -D

