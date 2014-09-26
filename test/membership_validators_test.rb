require_relative 'test_helper'

module GitHubLdapMembershipValidatorsTestCases
  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_validates_user_in_group
    validator = make_validator(%w(Enterprise))
    assert validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_group
    validator = make_validator(%w(People))
    refute validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_any_group
    @entry = @domain.user?('ldaptest')
    validator = make_validator(%w(Enterprise People))
    refute validator.perform(@entry)
  end
end

class GitHubLdapMembershipValidatorsClassicTest < GitHub::Ldap::Test
  include GitHubLdapMembershipValidatorsTestCases

  def self.test_server_options
    { search_domains: "dc=github,dc=com",
      uid: "uid"
    }
  end

  def setup
    @ldap      = GitHub::Ldap.new(options)
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('calavera')
    @validator = GitHub::Ldap::MembershipValidators::Classic
  end
end

class GitHubLdapMembershipValidatorsRecursiveTest < GitHub::Ldap::Test
  include GitHubLdapMembershipValidatorsTestCases

  def self.test_server_options
    { search_domains: "dc=github,dc=com",
      uid: "uid"
    }
  end

  def setup
    @ldap      = GitHub::Ldap.new(options)
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('calavera')
    @validator = GitHub::Ldap::MembershipValidators::Recursive
  end
end
