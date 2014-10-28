# Local ActiveDirectory Integration Testing

Integration tests are not run for ActiveDirectory in continuous integration
because we cannot install a Windows VM on TravisCI. To test ActiveDirectory,
configure a local VM with AD running.

From the project root, run:

```sh
$ cp test/support/vm/activedirectory/env.sh{.example,}

# edit ad-env.sh and fill in with your VM's values, then
$ source test/support/vm/activedirectory/env.sh

# run all tests against AD
$ time bundle exec rake

# run a specific test file against AD
$ time bundle exec ruby test/membership_validators/active_directory_test.rb

# reset environment to test other ldap servers
$ source test/support/vm/activedirectory/reset-env.sh
```
