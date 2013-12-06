# CNCFlora Public Web Services 

Public webservices and documentation, using [swagger](https://developers.helloreverb.com/swagger/).

## Deployment

### Docker/CI

TODO

### Manual

TODO

## Development

Start with git, obviously:

    # aptitude install git

Now clone the app, and enter it's directory:

    $ git clone git@github.com:CNCFlora/Services.git 
    $ cd Services

### Vagrant

The default is to use vagrant to simplify development, install [VirtualBox](http://virtualbox.org) and [Vagrant](http://vagrantup.org) and start the VM:

    $ vagrant up

And, to run the server:

    $ vagrant ssh -c "cd /vagrant && rackup"

To run tests:

    $ vagrant ssh -c "cd /vagrant && rspec app_test.rb"

The app will be running on 9494 and couchdb on 5999. 

