require_relative '../test_helper'

class GitHubLdapActiveDirectoryMembershipValidatorsStubbedTest < GitHub::Ldap::Test
  # Only run when AD integration tests aren't run
  def run(*)
    return super if self.class.test_env != "activedirectory"
    Minitest::Result.from(self)
  end

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
    validator = make_validator(%w(nested-group1))

    @ldap.stub :search, [@entry] do
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_child_group
    validator = make_validator(%w(n-depth-nested-group1))

    @ldap.stub :search, [@entry] do
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_grandchild_group
    validator = make_validator(%w(n-depth-nested-group2))

    @ldap.stub :search, [@entry] do
      assert validator.perform(@entry)
    end
  end

  def test_validates_user_in_great_grandchild_group
    validator = make_validator(%w(n-depth-nested-group3))

    @ldap.stub :search, [@entry] do
      assert validator.perform(@entry)
    end
  end

  def test_does_not_validate_user_not_in_group
    validator = make_validator(%w(ghe-admins))

    @ldap.stub :search, [] do
      refute validator.perform(@entry)
    end
  end

  def test_does_not_validate_user_not_in_any_group
    entry = @domain.user?('groupless-user1')
    validator = make_validator(%w(all-users))

    @ldap.stub :search, [] do
      refute validator.perform(entry)
    end
  end
end

# See test/support/vm/activedirectory/README.md for details
class GitHubLdapActiveDirectoryMembershipValidatorsIntegrationTest < GitHub::Ldap::Test
  # Only run this test suite if ActiveDirectory is configured
  def run(*)
    return super if self.class.test_env == "activedirectory"
    Minitest::Result.from(self)
  end

  def setup
    @ldap      = GitHub::Ldap.new(options)
    @domain    = @ldap.domain(options[:search_domains])
    @entry     = @domain.user?('user1')
    @validator = GitHub::Ldap::MembershipValidators::ActiveDirectory
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
    skip "update AD ldif to have a groupless user"
    @entry = @domain.user?('groupless-user1')
    validator = make_validator(%w(all-users))
    refute validator.perform(@entry)
  end

  def test_validates_user_in_posix_group
    validator = make_validator(%w(posix-group1))
    assert validator.perform(@entry)
  end

  def test_validates_user_in_group_with_differently_cased_dn
    validator = make_validator(%w(all-users))
    @entry[:dn].map(&:upcase!)
    assert validator.perform(@entry)

    @entry[:dn].map(&:downcase!)
    assert validator.perform(@entry)
  end
end
