require_relative 'test_helper'

module GitHubLdapMembershipValidatorsTestCases
  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_validates_user_in_group
    validator = make_validator(%w(ghe-users))
    assert validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_group
    validator = make_validator(%w(ghe-admins))
    refute validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_any_group
    @entry = @domain.user?('groupless-user1')
    validator = make_validator(%w(ghe-users ghe-admins))
    refute validator.perform(@entry)
  end
end

class GitHubLdapMembershipValidatorsClassicTest < GitHub::Ldap::Test
  include GitHubLdapMembershipValidatorsTestCases

  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: "dc=github,dc=com"))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::Classic
  end
end

class GitHubLdapMembershipValidatorsRecursiveTest < GitHub::Ldap::Test
  include GitHubLdapMembershipValidatorsTestCases

  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: "dc=github,dc=com"))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::Recursive
  end
end
