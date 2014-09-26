require_relative '../test_helper'

class GitHubLdapClassicMembershipValidatorsTest < GitHub::Ldap::Test
  def self.test_server_options
    { search_domains: "dc=github,dc=com",
      user_fixtures: FIXTURES.join('github-with-subgroups.ldif').to_s
    }
  end

  def setup
    @ldap      = GitHub::Ldap.new(options)
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1.1.1.1')
    @validator = GitHub::Ldap::MembershipValidators::Classic
  end

  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_validates_user_in_group
    validator = make_validator(%w(group1.1.1.1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_child_group
    validator = make_validator(%w(group1.1.1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_grandchild_group
    validator = make_validator(%w(group1.1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_great_grandchild_group
    validator = make_validator(%w(group1))
    assert validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_group
    validator = make_validator(%w(Enterprise))
    refute validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_any_group
    @entry = @domain.user?('admin')
    validator = make_validator(%w(Enterprise))
    refute validator.perform(@entry)
  end
end
