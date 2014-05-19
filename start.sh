#!/bin/bash

cd /root/services

[[ ! -e config.yml ]] && cp config.yml.dist config.yml

unicorn

