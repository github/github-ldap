# Local OpenLDAP Integration Testing

Set up a [Vagrant](http://www.vagrantup.com/) VM to run tests against OpenLDAP locally.

To run tests against OpenLDAP (instead of ApacheDS) locally:

``` bash
# start VM (from the correct directory)
$ cd test/support/vm/openldap/
$ vagrant up

# get the IP address of the VM
$ ip=$(vagrant ssh -- "ifconfig eth1 | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1")

# change back to root project directory
$ cd ../../../..

# run all tests against OpenLDAP
$ time TESTENV=openldap INTEGRATION_HOST=$ip bundle exec rake

# run a specific test file against OpenLDAP
$ time TESTENV=openldap INTEGRATION_HOST=$ip bundle exec ruby test/membership_validators/recursive_test.rb

# run OpenLDAP tests by default
$ export TESTENV=openldap
$ export TESTENV=$ip

# now run tests without having to set ENV variables
$ time bundle exec rake
```

You may need to `gem install vagrant` first in order to provision the VM.
