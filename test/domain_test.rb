require 'test_helper'

module GitHubLdapDomainTestCases
  def setup
    @domain = GitHub::Ldap.new(options).domain("dc=github,dc=com")
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

    assert @domain.is_member?(user.dn, %w(Enterprise People)),
      "Expected `Enterprise` or `Poeple` to include the member `#{user.dn}`"
  end

  def test_user_not_in_different_group
    user = @domain.valid_login?('calavera', 'passworD1')

    assert !@domain.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_user_without_group
    user = @domain.valid_login?('ldaptest', 'secret')

    assert !@domain.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
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
    assert @domain.membership('uid=calavera,dc=github,dc=com', %w(People)).empty?,
      "Expected `calavera` not to be a member of `People`."
  end

  def test_membership_groups_for_members
    groups = @domain.membership('uid=calavera,dc=github,dc=com', %w(Enterprise People))

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
