require_relative 'test_helper'

class GitHubLdapGroupTest < GitHub::Ldap::Test
  def groups_domain
    @ldap.domain("ou=Groups,dc=github,dc=com")
  end

  def setup
    @ldap  = GitHub::Ldap.new(options)
    @group = @ldap.group("cn=ghe-users,ou=Groups,dc=github,dc=com")
  end

  def test_group?
    assert @group.group?(%w(group))
    assert @group.group?(%w(groupOfUniqueNames))
    assert @group.group?(%w(posixGroup))

    object_classes = %w(groupOfNames)
    assert @group.group?(object_classes)
    assert @group.group?(object_classes.map(&:downcase))
  end

  def test_subgroups
    group = @ldap.group("cn=deeply-nested-group0.0,ou=Groups,dc=github,dc=com")
    assert_equal 2, group.subgroups.size
  end

  def test_members_from_subgroups
    group = @ldap.group("cn=deeply-nested-group0.0,ou=Groups,dc=github,dc=com")
    assert_equal 10, group.members.size
  end

  def test_all_domain_groups
    groups = groups_domain.all_groups
    assert_equal 27, groups.size
  end

  def test_filter_domain_groups
    groups = groups_domain.filter_groups('ghe-users')
    assert_equal 1, groups.size
  end

  def test_filter_domain_groups_limited
    groups = []
    groups_domain.filter_groups('deeply-nested-group', size: 1) do |entry|
      groups << entry
    end
    assert_equal 1, groups.size
  end

  def test_filter_domain_groups_unlimited
    groups = groups_domain.filter_groups('deeply-nested-group')
    assert_equal 5, groups.size
  end

  def test_unknown_group
    refute @ldap.group("cn=foobar,ou=groups,dc=github,dc=com"),
      "Expected to not bind any group"
  end
end

class GitHubLdapLoopedGroupTest < GitHub::Ldap::Test
  def setup
    @group = GitHub::Ldap.new(options).group("cn=recursively-nested-groups,ou=Groups,dc=github,dc=com")
  end

  def test_members_from_subgroups
    assert_equal 10, @group.members.size
  end
end

class GitHubLdapMissingEntriesTest < GitHub::Ldap::Test
  def setup
    @ldap = GitHub::Ldap.new(options)
  end

  def test_load_right_members
    assert_equal 3, @ldap.domain("cn=missing-users,ou=groups,dc=github,dc=com").bind[:member].size
  end

  def test_ignore_missing_member_entries
    assert_equal 2, @ldap.group("cn=missing-users,ou=groups,dc=github,dc=com").members.size
  end
end
