require 'test_helper'

class GitHubLdapTest < Minitest::Test
  def setup
    GitHub::Ldap.start_server

    @options = GitHub::Ldap.server_options.merge \
      host: 'localhost',
      uid:  'uid'

    @ldap = GitHub::Ldap.new(@options)
  end

  def teardown
    GitHub::Ldap.stop_server
  end

  def test_connection_with_default_options
    assert @ldap.test_connection, "Ldap connection expected to succeed"
  end

  def test_user_valid_login
    user = @ldap.valid_login?('calavera', 'secret')
    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_user_with_invalid_password
    assert !@ldap.valid_login?('calavera', 'foo'),
      "Login `calavera` expected to be invalid with password `foo`"
  end

  def test_user_with_invalid_login
    assert !@ldap.valid_login?('bar', 'foo'),
      "Login `bar` expected to be invalid with password `foo`"
  end

  def test_groups_in_server
    assert_equal 2, @ldap.groups(%w(Enterprise People)).size
  end

  def test_user_in_group
    user = @ldap.valid_login?('calavera', 'secret')

    assert @ldap.is_member?(user.dn, %w(Enterprise People)),
      "Expected `Enterprise` or `Poeple` to include the member `#{user.dn}`"
  end

  def test_user_not_in_different_group
    user = @ldap.valid_login?('calavera', 'secret')

    assert !@ldap.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_user_without_group
    user = @ldap.valid_login?('ldaptest', 'secret')

    assert !@ldap.is_member?(user.dn, %w(People)),
      "Expected `Poeple` not to include the member `#{user.dn}`"
  end

  def test_authenticate_doesnt_return_invalid_users
    user = @ldap.authenticate!('calavera', 'secret')
    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_invalid_users
    assert !@ldap.authenticate!('calavera', 'foo'),
      "Expected `authenticate!` to not return an invalid user"
  end

  def test_authenticate_check_valid_user_and_groups
    user = @ldap.authenticate!('calavera', 'secret', %w(Enterprise People))

    assert_equal 'uid=calavera,dc=github,dc=com', user.dn
  end

  def test_authenticate_doesnt_return_valid_users_in_different_groups
    assert !@ldap.authenticate!('calavera', 'secret', %w(People)),
      "Expected `authenticate!` to not return an user"
  end

  def test_simple_tls
    assert_equal :simple_tls, @ldap.check_encryption(:ssl)
    assert_equal :simple_tls, @ldap.check_encryption(:simple_tls)
  end

  def test_start_tls
    assert_equal :start_tls, @ldap.check_encryption(:tls)
    assert_equal :start_tls, @ldap.check_encryption(:start_tls)
  end

  def test_membership_empty_for_non_members
    assert @ldap.membership('uid=calavera,dc=github,dc=com', %w(People)).empty?,
      "Expected `calavera` not to be a member of `People`."
  end

  def test_membership_groups_for_members
    groups = @ldap.membership('uid=calavera,dc=github,dc=com', %w(Enterprise People))

    assert_equal 1, groups.size
    assert_equal 'cn=Enterprise,ou=Group,dc=github,dc=com', groups.first.dn
  end
end
