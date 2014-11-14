require_relative 'test_helper'

class GitHubLdapMembershipValidatorsTest < GitHub::Ldap::Test
  def setup
    @ldap = GitHub::Ldap.new(options.merge(search_domains: "dc=github,dc=com"))
  end

  def test_defaults_to_detect_strategy
    assert_equal :detect, @ldap.membership_validator
  end

  def test_configured_to_classic_strategy
    @ldap.configure_membership_validation_strategy :classic
    assert_equal :classic, @ldap.membership_validator
  end

  def test_configured_to_recursive_strategy
    @ldap.configure_membership_validation_strategy :recursive
    assert_equal :recursive, @ldap.membership_validator
  end

  def test_configured_to_active_directory_strategy
    @ldap.configure_membership_validation_strategy :active_directory
    assert_equal :active_directory, @ldap.membership_validator
  end

  def test_misconfigured_to_unrecognized_strategy_falls_back_to_default
    @ldap.configure_membership_validation_strategy :unknown
    assert_equal :detect, @ldap.membership_validator
  end
end
