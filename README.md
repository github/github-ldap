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

GitHub-Ldap let you use an external ldap server to authenticate your users with.

There are a few configuration options required to use this adapter:

* host: is the host address where the ldap server lives.
* port: is the port where the ldap server lives.
* admin_user: is the the ldap administrator user. Required to perform search operation.
* admin_password: is the password for the administrator user. Simple authentication is required on the server.
* encryptation: is the encryptation protocol, disabled by default. The valid options are `ssl` and `tls`.
* user_domain: is the default ldap domain base.
* uid: is the field name in the ldap server used to authenticate your users, in ActiveDirectory this is `sAMAccountName`.

Initialize a new adapter using those required options:

```ruby
  ldap = GitHub::Ldap.new options
```

## Testing

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
    users_fixtures: ldif_path
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
