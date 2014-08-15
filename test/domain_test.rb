require 'test_helper'

module GitHubLdapDomainTestCases
  def setup
    @ldap   = GitHub::Ldap.new(options)
    @domain = @ldap.domain("dc=github,dc=com")
  end

  def test_user_valid_login
    user = @domain.valid_login?('calavera', 'passworD1')
    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_user_with_invalid_password
    assert !@domain.valid_login?('calavera', 'foo'),
      "Login `calavera` expected to be invalid with password `foo`"
  end

  def test_user_with_invalid_login
    assert !@domain.valid_login?('bar', 'foo'),
      "Login `bar` expected to be invalid with password `foo`"
  end

  def test_groups_in_server
    assert_equal 2, @domain.groups(%w(Enterprise People)).size
  end

  def test_user_in_group
    user = @domain.valid_login?('calavera', 'passworD1')

    assert @domain.is_member?(user, %w(Enterprise People)),
      "Expected `Enterprise` or `Poeple` to include the member `#{user.dn}`"
  end

  def test_user_not_in_different_group
    user = @domain.valid_login?('calavera', 'passworD1')

    assert !@domain.is_member?(user, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_user_without_group
    user = @domain.valid_login?('ldaptest', 'secret')

    assert !@domain.is_member?(user, %w(People)),
      "Expected `People` not to include the member `#{user.dn}`"
  end

  def test_authenticate_doesnt_return_invalid_users
    user = @domain.authenticate!('calavera', 'passworD1')
    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_invalid_users
    assert !@domain.authenticate!('calavera', 'foo'),
      "Expected `authenticate!` to not return an invalid user"
  end

  def test_authenticate_check_valid_user_and_groups
    user = @domain.authenticate!('calavera', 'passworD1', %w(Enterprise People))

    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_valid_users_in_different_groups
    assert !@domain.authenticate!('calavera', 'passworD1', %w(People)),
      "Expected `authenticate!` to not return an user"
  end

  def test_membership_empty_for_non_members
    user = @ldap.domain('uid=calavera,dc=github,dc=com').bind

    assert @domain.membership(user, %w(People)).empty?,
      "Expected `calavera` not to be a member of `People`."
  end

  def test_membership_groups_for_members
    user = @ldap.domain('uid=calavera,dc=github,dc=com').bind
    groups = @domain.membership(user, %w(Enterprise People))

    assert_equal 1, groups.size
    assert_equal 'cn=Enterprise,ou=Group,dc=github,dc=com', groups.first.dn
  end

  def test_membership_with_virtual_attributes
    ldap = GitHub::Ldap.new(options.merge(virtual_attributes: true))
    user = ldap.domain('uid=calavera,dc=github,dc=com').bind
    user[:memberof] = 'cn=Enterprise,ou=Group,dc=github,dc=com'

    domain = ldap.domain("dc=github,dc=com")
    groups = domain.membership(user, %w(Enterprise People))

    assert_equal 1, groups.size
    assert_equal 'cn=Enterprise,ou=Group,dc=github,dc=com', groups.first.dn
  end

  def test_search
    assert 1, @domain.search(
      attributes: %w(uid),
      filter: Net::LDAP::Filter.eq('uid', 'calavera')).size
  end

  def test_search_override_base_name
    assert 1, @domain.search(
      base: "this base name is incorrect",
      attributes: %w(uid),
      filter: Net::LDAP::Filter.eq('uid', 'calavera')).size
  end

  def test_user_exists
    assert_equal 'uid=calavera,dc=github,dc=com', @domain.user?('calavera').dn
  end

  def test_user_wildcards_are_filtered
    assert !@domain.user?('cal*'), 'Expected uid `cal*` to not complete'
  end

  def test_user_does_not_exist
    assert !@domain.user?('foobar'), 'Expected uid `foobar` to not exist.'
  end

  def test_user_returns_every_attribute
    assert_equal ['calavera@github.com'], @domain.user?('calavera')[:mail]
  end

  def test_auth_binds
    user = @domain.user?('calavera')
    assert @domain.auth(user, 'passworD1'), 'Expected user to be bound.'
  end

  def test_auth_does_not_bind
    user = @domain.user?('calavera')
    assert !@domain.auth(user, 'foo'), 'Expected user not to be bound.'
  end
end

class GitHubLdapDomainTest < GitHub::Ldap::Test
  include GitHubLdapDomainTestCases
end

class GitHubLdapDomainUnauthenticatedTest < GitHub::Ldap::UnauthenticatedTest
  include GitHubLdapDomainTestCases
end

class GitHubLdapDomainNestedGroupsTest < GitHub::Ldap::Test
  def self.test_server_options
    {user_fixtures: FIXTURES.join('github-with-subgroups.ldif').to_s}
  end

  def setup
    @ldap = GitHub::Ldap.new(options)
    @domain = @ldap.domain("dc=github,dc=com")
  end

  def test_membership_in_subgroups
    user = @ldap.domain('uid=rubiojr,ou=users,dc=github,dc=com').bind

    assert @domain.is_member?(user, %w(enterprise-ops)),
      "Expected `enterprise-ops` to include the member `#{user.dn}`"
  end
end

class GitHubLdapPosixGroupsTest < GitHub::Ldap::Test
  def self.test_server_options
    {user_fixtures: FIXTURES.join('github-with-subgroups.ldif').to_s}
  end

  def setup
    @ldap = GitHub::Ldap.new(options)
    @domain = @ldap.domain("dc=github,dc=com")

    @group = Net::LDAP::Entry._load("""
dn: cn=enterprise-posix-devs,ou=groups,dc=github,dc=com
cn: enterprise-posix-devs
objectClass: posixGroup
memberUid: benburkert
memberUid: mtodd""")
  end

  def test_membership_for_posixGroups
    assert user = @ldap.domain('uid=mtodd,ou=users,dc=github,dc=com').bind

    assert @domain.is_member?(user, @group.cn),
      "Expected `#{@group.cn}` to include the member `#{user.dn}`"
  end
end
