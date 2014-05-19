#!/usr/bin/env bash

# basic stuff
apt-get update
apt-get upgrade -y
apt-get install aptitude wget curl git tmux vim libxslt-dev libxml2-dev ruby1.9.1 ruby1.9.1-dev libssl-dev build-essential -y

# add rbenv
if [[ ! -e /home/vagrant/.rbenv ]]; then
    su vagrant -lc 'git clone https://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv'
    su vagrant -lc 'echo export PATH="/home/vagrant/.rbenv/bin:\$PATH" >> /home/vagrant/.profile'
    su vagrant -lc 'echo export PATH="/home/vagrant/.rbenv/bin:\$PATH" >> /home/vagrant/.bashrc'
    su vagrant -lc 'echo eval \"\$\(rbenv init -\)\" >> /home/vagrant/.profile'
    su vagrant -lc 'echo eval \"\$\(rbenv init -\)\" >> /home/vagrant/.bashrc'
    su vagrant -lc 'git clone https://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build'
fi

# setup app deps
if [[ ! -e /home/vagrant/.app_done ]]; then
    # config ruby gems to use https
    gem sources -r http://rubygems.org
    gem sources -r http://rubygems.org/
    gem sources -a https://rubygems.org

    # initial config of app
    su vagrant -lc 'cd /vagrant && rbenv install $(cat .ruby-version) && rbenv rehash'
    su vagrant -lc 'cd /vagrant && gem install bundler && rbenv rehash'
    su vagrant -lc 'cd /vagrant && bundle install && rbenv rehash'
    su vagrant -lc 'cd /vagrant && [[ ! -e config.yml ]] && cp config.yml.dist config.yml'
    su vagrant -lc 'touch /home/vagrant/.app_done'
fi

# docker register to etcd
if [[ ! -e /usr/bin/docker2etcd ]]; then
    wget https://gist.githubusercontent.com/diogok/9604900/raw/afcc71dbec207a4f7b12a98e695622d902b5b022/register-docker-to-etcd.sh \
          -O /usr/bin/docker2etcd 
    chmod +x /usr/bin/docker2etcd 
fi
/usr/bin/docker2etcd

if [[ ! -e /home/vagrant/.db_done]]; then
    # setup couchdb
    curl -X PUT http://localhost:5984/cncflora
    curl -X PUT http://localhost:5984/cncflora_history
    curl -X PUT http://localhost:5984/cncflora_test
    curl -X PUT http://localhost:5984/cncflora_test_history

    # setup elasticsearch
    curl -X PUT http://localhost:9200/cncflora
    curl -X PUT http://localhost:9200/cncflora_test

    # datahub
    cd ~
    aptitude install erlang
    git clone https://github.com/CNCFlora/Datahub.git datahub
    cd datahub
    ./erica push assessments http://localhost:5984/cncflora
    ./erica push assessments http://localhost:5984/cncflora_test
    cd ..
    chown vagrant datahub -Rf
fi

echo "Done"

