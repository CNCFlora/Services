# CNCFlora Public Web Services 

Public webservices and documentation, using [swagger](https://developers.helloreverb.com/swagger/).

Access at [CNCFlora Services](http://cncflora.jbrj.gov.br/services).

## Deployment

### Docker/CI

    docker run -d -p 8080:8080 -t cncflora/services

### Manual

TODO

## Development

Start with git, obviously:

    # aptitude install git

Now clone the app, and enter it's directory:

    $ git clone git@github.com:CNCFlora/Services.git services
    $ cd services

### Vagrant

The default is to use vagrant to simplify development, install [VirtualBox](http://virtualbox.org) and [Vagrant](http://vagrantup.org) and start the VM:

    $ vagrant up

And, to run the server:

    $ vagrant ssh -c "cd /vagrant && rackup"

To run tests:

    $ vagrant ssh -c "cd /vagrant && rspec app_test.rb"

The app will be running on 9292.


## License

Apache License 2.0

