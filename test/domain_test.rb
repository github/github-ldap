require 'test_helper'

class GitHubLdapDomainTest < Minitest::Test
  def setup
    GitHub::Ldap.start_server

    @options = GitHub::Ldap.server_options.merge \
      host: 'localhost',
      uid:  'uid'

    @domain = GitHub::Ldap.new(@options).domain("dc=github,dc=com")
  end

  def teardown
    GitHub::Ldap.stop_server
  end

  def test_user_valid_login
    user = @domain.valid_login?('calavera', 'secret')
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
    user = @domain.valid_login?('calavera', 'secret')

    assert @domain.is_member?(user.dn, %w(Enterprise People)),
      "Expected `Enterprise` or `Poeple` to include the member `#{user.dn}`"
  end

  def test_user_not_in_different_group
    user = @domain.valid_login?('calavera', 'secret')

    assert !@domain.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_user_without_group
    user = @domain.valid_login?('ldaptest', 'secret')

    assert !@domain.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_authenticate_doesnt_return_invalid_users
    user = @domain.authenticate!('calavera', 'secret')
    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_invalid_users
    assert !@domain.authenticate!('calavera', 'foo'),
      "Expected `authenticate!` to not return an invalid user"
  end

  def test_authenticate_check_valid_user_and_groups
    user = @domain.authenticate!('calavera', 'secret', %w(Enterprise People))

    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_valid_users_in_different_groups
    assert !@domain.authenticate!('calavera', 'secret', %w(People)),
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
end

