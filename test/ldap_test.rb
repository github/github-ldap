require 'test_helper'

module GitHubLdapTestCases
  def setup
    @ldap = GitHub::Ldap.new(options)
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

  def test_search_delegator
    @ldap.domain('dc=github,dc=com').valid_login? 'calavera', 'secret'

    result = @ldap.search(
        {:base      => 'dc=github,dc=com',
        :attributes => %w(uid),
        :filter     => Net::LDAP::Filter.eq('uid', 'calavera')})

    assert_equal 'calavera', result.first[:uid].first
  end
end

class GitHubLdapTest < GitHub::Ldap::Test
  include GitHubLdapTestCases
end

class GitHubLdapUnauthenticatedTest < GitHub::Ldap::UnauthenticatedTest
  include GitHubLdapTestCases
end
