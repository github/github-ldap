require_relative '../test_helper'

# NOTE: Since this strategy is targeted at ActiveDirectory and we don't have
# AD setup in CI, we stub out actual queries and test against what AD *would*
# respond with.

class GitHubLdapActiveDirectoryMembershipValidatorsTest < GitHub::Ldap::Test
  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::ActiveDirectory
  end

  def make_validator(groups)
    groups = @domain.groups(groups)
    @validator.new(@ldap, groups)
  end

  def test_validates_user_in_group
    @ldap.stub :search, [@entry] do
      validator = make_validator(%w(nested-group1))
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_child_group
    @ldap.stub :search, [@entry] do
      validator = make_validator(%w(n-depth-nested-group1))
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_grandchild_group
    @ldap.stub :search, [@entry] do
      validator = make_validator(%w(n-depth-nested-group2))
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_great_grandchild_group
    @ldap.stub :search, [@entry] do
      validator = make_validator(%w(n-depth-nested-group3))
      assert validator.perform(@entry)
    end
  end

  def test_does_not_validate_user_not_in_group
    @ldap.stub :search, [] do
      validator = make_validator(%w(ghe-admins))
      refute validator.perform(@entry)
    end
  end

  def test_does_not_validate_user_not_in_any_group
    entry = @domain.user?('groupless-user1')

    @ldap.stub :search, [] do
      validator = make_validator(%w(all-users))
      refute validator.perform(entry)
    end
  end
end