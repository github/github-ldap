<a href="https://travis-ci.org/github/github-ldap">![Build Status](https://travis-ci.org/github/github-ldap.png?branch=master)</a>

# Github::Ldap

GitHub-Ldap is a wrapper on top of Net::LDAP to make it human friendly.

## Installation

Add this line to your application's Gemfile:

    gem 'github-ldap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install github-ldap

## Usage

### Initialization

GitHub-Ldap let you use an external ldap server to authenticate your users with.

There are a few configuration options required to use this adapter:

* host: is the host address where the ldap server lives.
* port: is the port where the ldap server lives.
* hosts: (optional) an enumerable of pairs of hosts and corresponding ports with which to attempt opening connections (default [[host, port]]). Overrides host and port if set.
* encryption: is the encryption protocol, disabled by default. The valid options are `ssl` and `tls`.
* uid: is the field name in the ldap server used to authenticate your users, in ActiveDirectory this is `sAMAccountName`.

Using administrator credentials is optional but recommended. You can pass those credentials with these two options:

* admin_user: is the the ldap administrator user dn.
* admin_password: is the password for the administrator user.

Initialize a new adapter using those required options:

```ruby
  ldap = GitHub::Ldap.new options
```

See GitHub::Ldap#initialize for additional options.

### Querying

Searches are performed against an individual domain base, so the first step is to get a new `GitHub::Ldap::Domain` object for the connection:

```ruby
  ldap = GitHub::Ldap.new options
  domain = ldap.domain("dc=github,dc=com")
```

When we have the domain, we can check if a user can log in with a given password:

```ruby
  domain.valid_login? 'calavera', 'secret'
```

Or whether a user is member of the given groups:

```ruby
  entry = ldap.domain('uid=calavera,dc=github,dc=com').bind
  domain.is_member? entry, %w(Enterprise)
```

### Virtual Attributes

Some LDAP servers have support for virtual attributes, or overlays. These allow to perform queries more efficiently on the server.

To enable virtual attributes you can set the option `virtual_attributes` initializing the ldap connection.
We use our default set of virtual names if this option is just set to `true`.

```ruby
  ldap = GitHub::Ldap.new {virtual_attributes: true}
```

You can also override our defaults by providing your server mappings into a Hash.
The only mapping supported for now is to check virtual membership of individuals in groups.

```ruby
  ldap = GitHub::Ldap.new {virtual_attributes: {virtual_membership: 'memberOf'}}
```

### Testing support

GitHub-Ldap uses [ladle](https://github.com/NUBIC/ladle) for testing. Ladle is not required by default, so you'll need to add it to your gemfile separatedly and require it.

Once you have it installed you can start the testing ldap server in the setup phase for your tests:

```ruby
require 'github/ldap/server'

def setup
  GitHub::Ldap.start_server
end

def teardown
  GitHub::Ldap.stop_server
end
```

GitHub-Ldap includes a set of configured users for testing, but you can provide your own users into a ldif file:

```ruby
def setup
  GitHub::Ldap.start_server \
    user_fixtures: ldif_path
end
```

If you provide your own user fixtures, you'll probably need to change the default user domain, the administrator name and her password:

```ruby
def setup
  GitHub::Ldap.start_server \
    user_fixtures:  ldif_path,
    user_domain:    'dc=evilcorp,dc=com'
    admin_user:     'uid=eviladmin,dc=evilcorp,dc=com',
    admin_password: 'correct horse battery staple'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Releasing

This section is for gem maintainers to cut a new version of the gem. See
[jch/release-scripts](https://github.com/jch/release-scripts) for original
source of release scripts.

* Create a new branch from `master` named `release-x.y.z`, where `x.y.z` is the version to be released
* Update `github-ldap.gemspec` to x.y.z following [semver](http://semver.org)
* Run `script/changelog` and paste the draft into `CHANGELOG.md`. Edit as needed
* Create pull request to solict feedback
* After merging the pull request, on the master branch, run `script/release`
