#!/bin/bash

#service nginx start
$USER=cncflora
su $USER -c 'cd ~/www && nohup rackup &'

/usr/sbin/sshd -D

