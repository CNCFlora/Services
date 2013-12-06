#!/usr/bin/env bash

# ruby, java, git, curl and couchdb
apt-get update
apt-get install ruby curl git couchdb libgd2-noxpm -y

cp /etc/rc.local /etc/rc.local.bkp
sudo sed -e 's/exit/#exit/g' /etc/rc.local.bkp > /etc/rc.local

# config ruby gems to https and rvm
gem sources -r http://rubygems.org/
gem sources -r http://rubygems.org
gem sources -a https://rubygems.org
gem install bundler

# config couchdb
service couchdb stop
cp /etc/couchdb/local.ini /etc/couchdb/local.ini.bkp
sudo sed -e 's/;bind_address = [0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+/bind_address = 0.0.0.0/' /etc/couchdb/local.ini.bkp > /etc/couchdb/local.ini 
echo "service couchdb start" >> /etc/rc.local
service couchdb start

# install the datahub design docs
cd ~
git clone https://github.com/CNCFlora/Datahub.git
cd Datahub
curl -X PUT "http://localhost:5984/cncflora"
curl -X PUT "http://localhost:5984/cncflora_test"
cp config.ini-dist config.ini
. config.ini
for f in $(ls -d */); do
    echo $f $DEV
    ./erica push $f $DEV
    ./erica push $f $TEST
done;
cd ..
echo "Done datahub"

# initial config of app
cd /vagrant
bundle install
[[ ! -e config.yml ]] && cp config.yml.dist config.yml
echo "Done bootstrap"

