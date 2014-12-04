require_relative '../test_helper'

# NOTE: Since this strategy is targeted at detecting ActiveDirectory
# capabilities, and we don't have AD setup in CI, we stub out actual queries
# and test against what AD *would* respond with.

class GitHubLdapDetectMembershipValidatorsTest < GitHub::Ldap::Test
  include GitHub::Ldap::Capabilities

  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::Detect
  end

  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_defers_to_configured_strategy
    @ldap.configure_membership_validation_strategy(:classic)
    validator = make_validator(%w(group))

    assert_kind_of GitHub::Ldap::MembershipValidators::Classic, validator.strategy
  end

  def test_detects_active_directory
    caps = Net::LDAP::Entry.new
    caps[:supportedcapabilities] = [ACTIVE_DIRECTORY_V61_R2_OID]

    validator = make_validator(%w(group))
    @ldap.stub :capabilities, caps do
      assert_kind_of GitHub::Ldap::MembershipValidators::ActiveDirectory,
        validator.strategy
    end
  end

  def test_falls_back_to_recursive
    caps = Net::LDAP::Entry.new
    caps[:supportedcapabilities] = []

    validator = make_validator(%w(group))
    @ldap.stub :capabilities, caps do
      assert_kind_of GitHub::Ldap::MembershipValidators::Recursive,
        validator.strategy
    end
  end
end
