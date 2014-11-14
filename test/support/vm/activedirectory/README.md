# Local ActiveDirectory Integration Testing

Integration tests are not run for ActiveDirectory in continuous integration
because we cannot install a Windows VM on TravisCI. To test ActiveDirectory,
configure a local VM with AD running (this is left as an exercise for the
reader).

To run integration tests against the local ActiveDirectory VM, from the project
root run:

``` bash
# duplicate example env.sh for specific config
$ cp test/support/vm/activedirectory/env.sh{.example,}

# edit env.sh and fill in with your VM's values, then
$ source test/support/vm/activedirectory/env.sh

# run all tests against AD
$ time bundle exec rake

# run a specific test file against AD
$ time bundle exec ruby test/membership_validators/active_directory_test.rb

# reset environment to test other LDAP servers
$ source test/support/vm/activedirectory/reset-env.sh
```
