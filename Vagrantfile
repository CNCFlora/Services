# -*- mode: ruby -*-
# vi: set ft=ruby

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.vm.network "private_network", ip: "192.168.50.15"
  config.vm.network :forwarded_port, host: 9292, guest: 9292, auto_correct: true
  config.vm.network :forwarded_port, host: 8080, guest: 8080, auto_correct: true

  config.vm.provision "docker" do |d|
    d.run "coreos/etcd", name: "etcd", args: "-p 4001:4001"
    d.run "cncflora/datahub", name: "datahub", args: "-P -v /var/couchdb:/var/lib/couchdb:rw"
  end

  config.vm.provision :shell, :path => "vagrant.sh"
end

