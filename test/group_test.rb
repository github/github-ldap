require 'test_helper'

class GitHubLdapGroupTest < GitHub::Ldap::Test
  def self.test_server_options
    {user_fixtures: FIXTURES.join('github-with-subgroups.ldif').to_s}
  end

  def setup
    @group = GitHub::Ldap.new(options).group("cn=enterprise,ou=groups,dc=github,dc=com")
  end

  def test_subgroups
    assert_equal 3, @group.subgroups.size
  end

  def test_members_from_subgroups
    assert_equal 4, @group.members.size
  end

  def test_all_domain_groups
    groups = GitHub::Ldap.new(options).domain("ou=groups,dc=github,dc=com").all_groups
    assert_equal 4, groups.size
  end
end
