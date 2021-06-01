require_relative 'test_helper'

module GitHubLdapDomainTestCases
  def setup
    @ldap   = GitHub::Ldap.new(options)
    @domain = @ldap.domain("dc=github,dc=com")
  end

  def test_user_valid_login
    assert user = @domain.valid_login?('user1', 'passworD1')
    assert_equal 'uid=user1,ou=People,dc=github,dc=com', user.dn
  end

  def test_user_with_invalid_password
    assert !@domain.valid_login?('user1', 'foo'),
      "Login `user1` expected to be invalid with password `foo`"
  end

  def test_user_with_invalid_login
    assert !@domain.valid_login?('bar', 'foo'),
      "Login `bar` expected to be invalid with password `foo`"
  end

  def test_groups_in_server
    assert_equal 2, @domain.groups(%w(ghe-users ghe-admins)).size
  end

  def test_user_in_group
    assert user = @domain.valid_login?('user1', 'passworD1')

    assert @domain.is_member?(user, %w(ghe-users ghe-admins)),
      "Expected `ghe-users` or `ghe-admins` to include the member `#{user.dn}`"
  end

  def test_user_not_in_different_group
    user = @domain.valid_login?('user1', 'passworD1')

    refute @domain.is_member?(user, %w(ghe-admins)),
      "Expected `ghe-admins` not to include the member `#{user.dn}`"
  end

  def test_user_without_group
    user = @domain.valid_login?('groupless-user1', 'passworD1')

    assert !@domain.is_member?(user, %w(all-users)),
      "Expected `all-users` not to include the member `#{user.dn}`"
  end

  def test_authenticate_returns_valid_users
    user = @domain.authenticate!('user1', 'passworD1')
    assert_equal 'uid=user1,ou=People,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_invalid_users
    refute @domain.authenticate!('user1', 'foo'),
      "Expected `authenticate!` to not return an invalid user"
  end

  def test_authenticate_check_valid_user_and_groups
    user = @domain.authenticate!('user1', 'passworD1', %w(ghe-users ghe-admins))

    assert_equal 'uid=user1,ou=People,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_valid_users_in_different_groups
    refute @domain.authenticate!('user1', 'passworD1', %w(ghe-admins)),
      "Expected `authenticate!` to not return an user"
  end

  def test_membership_empty_for_non_members
    user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    assert @domain.membership(user, %w(ghe-admins)).empty?,
      "Expected `user1` not to be a member of `ghe-admins`."
  end

  def test_membership_groups_for_members
    user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind
    groups = @domain.membership(user, %w(ghe-users ghe-admins))

    assert_equal 1, groups.size
    assert_equal 'cn=ghe-users,ou=Groups,dc=github,dc=com', groups.first.dn
  end

  def test_membership_with_virtual_attributes
    ldap = GitHub::Ldap.new(options.merge(virtual_attributes: true))

    user = ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind
    user[:memberof] = 'cn=ghe-admins,ou=Groups,dc=github,dc=com'

    domain = ldap.domain("dc=github,dc=com")
    groups = domain.membership(user, %w(ghe-admins))

    assert_equal 1, groups.size
    assert_equal 'cn=ghe-admins,ou=Groups,dc=github,dc=com', groups.first.dn
  end

  def test_search
    assert 1, @domain.search(
      attributes: %w(uid),
      filter: Net::LDAP::Filter.eq('uid', 'user1')).size
  end

  def test_search_override_base_name
    assert 1, @domain.search(
      base: "this base name is incorrect",
      attributes: %w(uid),
      filter: Net::LDAP::Filter.eq('uid', 'user1')).size
  end

  def test_user_exists
    assert user = @domain.user?('user1')
    assert_equal 'uid=user1,ou=People,dc=github,dc=com', user.dn
  end

  def test_user_wildcards_are_filtered
    refute @domain.user?('user*'), 'Expected uid `user*` to not complete'
  end

  def test_user_does_not_exist
    refute @domain.user?('foobar'), 'Expected uid `foobar` to not exist.'
  end

  def test_user_returns_every_attribute
    assert user = @domain.user?('user1')
    assert_equal ['user1@github.com'], user[:mail]
  end

  def test_user_returns_subset_of_attributes
    assert entry = @domain.user?('user1', :attributes => [:cn])
    assert_equal [:dn, :cn], entry.attribute_names
  end

  def test_auth_binds
    assert user = @domain.user?('user1')
    assert @domain.auth(user, 'passworD1'), 'Expected user to bind'
  end

  def test_auth_does_not_bind
    assert user = @domain.user?('user1')
    refute @domain.auth(user, 'foo'), 'Expected user not not bind'
  end

  def test_user_search_returns_first_entry
    entry = mock("Net::Ldap::Entry")
    search_strategy = mock("GitHub::Ldap::UserSearch::Default")
    search_strategy.stubs(:perform).returns([entry])
    @ldap.expects(:user_search_strategy).returns(search_strategy)
    user = @domain.user?('user1', :attributes => [:cn])
    assert_equal entry, user
  end
end

class GitHubLdapDomainTest < GitHub::Ldap::Test
  include GitHubLdapDomainTestCases
end

class GitHubLdapDomainUnauthenticatedTest < GitHub::Ldap::UnauthenticatedTest
  include GitHubLdapDomainTestCases
end

class GitHubLdapDomainNestedGroupsTest < GitHub::Ldap::Test
  def setup
    @ldap = GitHub::Ldap.new(options)
    @domain = @ldap.domain("dc=github,dc=com")
  end

  def test_membership_in_subgroups
    user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    assert @domain.is_member?(user, %w(nested-groups)),
      "Expected `nested-groups` to include the member `#{user.dn}`"
  end

  def test_membership_in_deeply_nested_subgroups
    assert user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    assert @domain.is_member?(user, %w(n-depth-nested-group4)),
      "Expected `n-depth-nested-group4` to include the member `#{user.dn}` via deep recursion"
  end
end

class GitHubLdapPosixGroupsWithRecursionFallbackTest < GitHub::Ldap::Test
  def setup
    opts = options.merge \
      recursive_group_search_fallback: true
    @ldap = GitHub::Ldap.new(opts)
    @domain = @ldap.domain("dc=github,dc=com")
    @cn = "posix-group1"
  end

  def test_membership_for_posixGroups
    assert user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    assert @domain.is_member?(user, [@cn]),
      "Expected `#{@cn}` to include the member `#{user.dn}`"
  end
end

class GitHubLdapPosixGroupsWithoutRecursionTest < GitHub::Ldap::Test
  def setup
    opts = options.merge \
      recursive_group_search_fallback: false
    @ldap = GitHub::Ldap.new(opts)
    @domain = @ldap.domain("dc=github,dc=com")
    @cn = "posix-group1"
  end

  def test_membership_for_posixGroups
    assert user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    assert @domain.is_member?(user, [@cn]),
      "Expected `#{@cn}` to include the member `#{user.dn}`"
  end
end

# Specifically testing that this doesn't break when posixGroups are not
# supported.
class GitHubLdapWithoutPosixGroupsTest < GitHub::Ldap::Test
  def setup
    opts = options.merge \
      recursive_group_search_fallback: false, # test non-recursive group membership search
      posix_support:                   false  # disable posixGroup support
    @ldap = GitHub::Ldap.new(opts)
    @domain = @ldap.domain("dc=github,dc=com")
    @cn = "posix-group1"
  end

  def test_membership_for_posixGroups
    assert user = @ldap.domain('uid=user1,ou=People,dc=github,dc=com').bind

    refute @domain.is_member?(user, [@cn]),
      "Expected `#{@cn}` to not include the member `#{user.dn}`"
  end
end

class GitHubLdapActiveDirectoryGroupsTest < GitHub::Ldap::Test
  def run(*)
    return super if self.class.test_env == "activedirectory"
    Minitest::Result.from(self)
  end

  def test_filter_groups
    domain = GitHub::Ldap.new(options).domain("DC=ad,DC=ghe,DC=local")
    results = domain.filter_groups("ghe-admins")
    assert_equal 1, results.size
  end
end
