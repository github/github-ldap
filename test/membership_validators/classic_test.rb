require_relative '../test_helper'

class GitHubLdapClassicMembershipValidatorsTest < GitHub::Ldap::Test
  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::Classic
  end

  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_validates_user_in_group
    validator = make_validator(%w(nested-group1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_child_group
    validator = make_validator(%w(n-depth-nested-group1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_grandchild_group
    validator = make_validator(%w(n-depth-nested-group2))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_great_grandchild_group
    validator = make_validator(%w(n-depth-nested-group3))
    assert validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_group
    validator = make_validator(%w(ghe-admins))
    refute validator.perform(@entry)
  end

  def test_does_not_validate_user_not_in_any_group
    @entry = @domain.user?('groupless-user1')
    validator = make_validator(%w(all-users))
    refute validator.perform(@entry)
  end

  def test_validates_user_in_posix_group
    validator = make_validator(%w(posix-group1))
    assert validator.perform(@entry)
  end
end
