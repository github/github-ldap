# CHANGELOG

# v1.10.1

* Bump net-ldap to 0.16.0

# v1.10.0

* Bump net-ldap to 0.15.0 [#92](https://github.com/github/github-ldap/pull/92)

# v1.9.0

* Update net-ldap dependency to `~> 0.11.0` [#84](https://github.com/github/github-ldap/pull/84)

# v1.8.2

* Ignore case when comparing ActiveDirectory DNs [#82](https://github.com/github/github-ldap/pull/82)

# v1.8.1

* Expand supported ActiveDirectory capabilities to include Windows Server 2003 [#80](https://github.com/github/github-ldap/pull/80)

# v1.8.0

* Optimize Recursive *Member Search* strategy [#78](https://github.com/github/github-ldap/pull/78)

# v1.7.1

* Add Active Directory group filter [#75](https://github.com/github/github-ldap/pull/75)

## v1.7.0

* Accept `:depth` option for Recursive membership validator strategy instance [#73](https://github.com/github/github-ldap/pull/73)
* Deprecate `depth` argument to `Recursive` membership validator `perform` method
* Bump net-ldap dependency to 0.10.0 at minimum [#72](https://github.com/github/github-ldap/pull/72)

## v1.6.0

* Expose `GitHub::Ldap::Group.group?` for testing if entry is a group [#67](https://github.com/github/github-ldap/pull/67)
* Add *Member Search* strategies [#64](https://github.com/github/github-ldap/pull/64) [#68](https://github.com/github/github-ldap/pull/68) [#69](https://github.com/github/github-ldap/pull/69)
* Simplify *Member Search* and *Membership Validation* search strategy configuration, detection, and default behavior [#70](https://github.com/github/github-ldap/pull/70)

## v1.5.0

* Automatically detect membership validator strategy by default [#58](https://github.com/github/github-ldap/pull/58) [#62](https://github.com/github/github-ldap/pull/62)
* Document local integration testing with Active Directory [#61](https://github.com/github/github-ldap/pull/61)

## v1.4.0

* Document constructor options [#57](https://github.com/github/github-ldap/pull/57)
* [CI] Add Vagrant box for running tests against OpenLDAP locally [#55](https://github.com/github/github-ldap/pull/55)
* Run all tests, including those in subdirectories [#54](https://github.com/github/github-ldap/pull/54)
* Add ActiveDirectory membership validator [#52](https://github.com/github/github-ldap/pull/52)
* Merge dev-v2 branch into master [#50](https://github.com/github/github-ldap/pull/50)
* Pass through search options for GitHub::Ldap::Domain#user? [#51](https://github.com/github/github-ldap/pull/51)
* Fix membership validation tests [#49](https://github.com/github/github-ldap/pull/49)
* Add CI build for OpenLDAP integration [#48](https://github.com/github/github-ldap/pull/48)
* Membership Validators [#45](https://github.com/github/github-ldap/pull/45)
