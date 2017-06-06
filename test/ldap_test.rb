require_relative 'test_helper'

module GitHubLdapTestCases
  def setup
    @ldap = GitHub::Ldap.new(options)
  end

  def test_connection_with_default_options
    assert @ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_connection_with_list_of_hosts_with_one_valid_host
    ldap = GitHub::Ldap.new(options.merge(hosts: [["localhost", options[:port]]]))
    assert ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_connection_with_list_of_hosts_with_first_valid
    ldap = GitHub::Ldap.new(options.merge(hosts: [["localhost", options[:port]], ["invalid.local", options[:port]]]))
    assert ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_connection_with_list_of_hosts_with_first_invalid
    ldap = GitHub::Ldap.new(options.merge(hosts: [["invalid.local", options[:port]], ["localhost", options[:port]]]))
    assert ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_simple_tls
    expected = { method: :simple_tls, tls_options:  { } }
    assert_equal expected, @ldap.check_encryption(:ssl)
    assert_equal expected, @ldap.check_encryption('SSL')
    assert_equal expected, @ldap.check_encryption(:simple_tls)
  end

  def test_start_tls
    expected = { method: :start_tls, tls_options: { } }
    assert_equal expected, @ldap.check_encryption(:tls)
    assert_equal expected, @ldap.check_encryption('TLS')
    assert_equal expected, @ldap.check_encryption(:start_tls)
  end

  def test_tls_validation
    assert_equal({ method: :start_tls, tls_options: { verify_mode: OpenSSL::SSL::VERIFY_PEER } },
                 @ldap.check_encryption(:tls, verify_mode: OpenSSL::SSL::VERIFY_PEER))
    assert_equal({ method: :start_tls, tls_options: { verify_mode: OpenSSL::SSL::VERIFY_NONE } },
                 @ldap.check_encryption(:tls, verify_mode: OpenSSL::SSL::VERIFY_NONE))
    assert_equal({ method: :start_tls, tls_options: { cert_store: "some/path" } },
                 @ldap.check_encryption(:tls, cert_store: "some/path"))
    assert_equal({ method: :start_tls, tls_options: {} },
                 @ldap.check_encryption(:tls, nil))
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

  def test_search_strategy_defaults
    assert_equal GitHub::Ldap::MembershipValidators::Recursive, @ldap.membership_validator
    assert_equal GitHub::Ldap::MemberSearch::Recursive,         @ldap.member_search_strategy
  end

  def test_search_strategy_detects_active_directory
    caps = Net::LDAP::Entry.new
    caps[:supportedcapabilities] = [GitHub::Ldap::ACTIVE_DIRECTORY_V51_OID]

    @ldap.stub :capabilities, caps do
      @ldap.configure_search_strategy :detect

      assert_equal GitHub::Ldap::MembershipValidators::ActiveDirectory, @ldap.membership_validator
      assert_equal GitHub::Ldap::MemberSearch::ActiveDirectory,         @ldap.member_search_strategy
    end
  end

  def test_search_strategy_configured_to_classic
    @ldap.configure_search_strategy :classic
    assert_equal GitHub::Ldap::MembershipValidators::Classic, @ldap.membership_validator
    assert_equal GitHub::Ldap::MemberSearch::Classic,         @ldap.member_search_strategy
  end

  def test_search_strategy_configured_to_recursive
    @ldap.configure_search_strategy :recursive
    assert_equal GitHub::Ldap::MembershipValidators::Recursive, @ldap.membership_validator
    assert_equal GitHub::Ldap::MemberSearch::Recursive,         @ldap.member_search_strategy
  end

  def test_search_strategy_configured_to_active_directory
    @ldap.configure_search_strategy :active_directory
    assert_equal GitHub::Ldap::MembershipValidators::ActiveDirectory, @ldap.membership_validator
    assert_equal GitHub::Ldap::MemberSearch::ActiveDirectory,         @ldap.member_search_strategy
  end

  def test_search_strategy_misconfigured_to_unrecognized_strategy_falls_back_to_default
    @ldap.configure_search_strategy :unknown
    assert_equal GitHub::Ldap::MembershipValidators::Recursive, @ldap.membership_validator
    assert_equal GitHub::Ldap::MemberSearch::Recursive,         @ldap.member_search_strategy
  end

  def test_user_search_strategy_global_catalog_when_configured
    @ldap.configure_user_search_strategy("global_catalog")
    assert_kind_of GitHub::Ldap::UserSearch::ActiveDirectory, @ldap.user_search_strategy
  end

  def test_user_search_strategy_default_when_configured
    @ldap.configure_user_search_strategy("default")
    refute_kind_of GitHub::Ldap::UserSearch::ActiveDirectory, @ldap.user_search_strategy
    assert_kind_of GitHub::Ldap::UserSearch::Default, @ldap.user_search_strategy
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
