require_relative 'test_helper'

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
    assert user = @ldap.domain('dc=github,dc=com').valid_login?('user1', 'passworD1')

    result = @ldap.search \
      :base      => 'dc=github,dc=com',
      :attributes => %w(uid),
      :filter     => Net::LDAP::Filter.eq('uid', 'user1')

    refute result.empty?
    assert_equal 'user1', result.first[:uid].first
  end

  def test_virtual_attributes_disabled
    refute @ldap.virtual_attributes.enabled?, "Expected to have virtual attributes disabled"
  end

  def test_virtual_attributes_configured
    ldap = GitHub::Ldap.new(options.merge(virtual_attributes: true))

    assert ldap.virtual_attributes.enabled?,
      "Expected virtual attributes to be enabled"
    assert_equal 'memberOf', ldap.virtual_attributes.virtual_membership
  end

  def test_virtual_attributes_configured_with_membership_attribute
    ldap = GitHub::Ldap.new(options.merge(virtual_attributes: {virtual_membership: "isMemberOf"}))

    assert ldap.virtual_attributes.enabled?,
      "Expected virtual attributes to be enabled"
    assert_equal 'isMemberOf', ldap.virtual_attributes.virtual_membership
  end

  def test_search_domains
    ldap = GitHub::Ldap.new(options.merge(search_domains: ['dc=github,dc=com']))
    result = ldap.search(filter: Net::LDAP::Filter.eq('uid', 'user1'))

    refute result.empty?
    assert_equal 'user1', result.first[:uid].first
  end

  def test_instruments_search
    events = @service.subscribe "search.github_ldap"
    result = @ldap.search(filter: "(uid=user1)", :base => "dc=github,dc=com")
    refute_predicate result, :empty?
    payload, event_result = events.pop
    assert payload
    assert event_result
    assert_equal result, event_result
    assert_equal "(uid=user1)",      payload[:filter].to_s
    assert_equal "dc=github,dc=com", payload[:base]
  end

  def test_membership_validator_default
    assert_equal :detect, @ldap.membership_validator
  end

  def test_capabilities
    assert_kind_of Net::LDAP::Entry, @ldap.capabilities
  end
end

class GitHubLdapTest < GitHub::Ldap::Test
  include GitHubLdapTestCases
end

class GitHubLdapUnauthenticatedTest < GitHub::Ldap::UnauthenticatedTest
  include GitHubLdapTestCases
end
