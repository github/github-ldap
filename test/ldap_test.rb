require 'test_helper'

class GitHubLdapTest < Minitest::Test
  def setup
    GitHub::Ldap.start_server

    @options = GitHub::Ldap.server_options.merge \
      host: 'localhost',
      uid:  'uid'

    @ldap = GitHub::Ldap.new(@options)
  end

  def teardown
    GitHub::Ldap.stop_server
  end

  def test_connection_with_default_options
    assert @ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_simple_tls
    assert_equal :simple_tls, @ldap.check_encryption(:ssl)
    assert_equal :simple_tls, @ldap.check_encryption('SSL')
    assert_equal :simple_tls, @ldap.check_encryption(:simple_tls)
  end

  def test_start_tls
    assert_equal :start_tls, @ldap.check_encryption(:tls)
    assert_equal :start_tls, @ldap.check_encryption('TLS')
    assert_equal :start_tls, @ldap.check_encryption(:start_tls)
  end
end
