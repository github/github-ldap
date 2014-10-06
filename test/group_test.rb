require_relative 'test_helper'

class GitHubLdapGroupTest < GitHub::Ldap::Test
  def groups_domain
    @ldap.domain("ou=groups,dc=github,dc=com")
  end

  def setup
    @ldap  = GitHub::Ldap.new(options)
    @group = @ldap.group("cn=enterprise,ou=groups,dc=github,dc=com")
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
    assert_equal 3, @group.subgroups.size
  end

  def test_members_from_subgroups
    assert_equal 4, @group.members.size
  end

  def test_all_domain_groups
    groups = groups_domain.all_groups
    assert_equal 8, groups.size
  end

  def test_filter_domain_groups
    groups = groups_domain.filter_groups('devs')
    assert_equal 1, groups.size
  end

  def test_filter_domain_groups_limited
    groups = []
    groups_domain.filter_groups('enter', size: 1) do |entry|
      groups << entry
    end
    assert_equal 1, groups.size
  end

  def test_filter_domain_groups_unlimited
    groups = groups_domain.filter_groups('ent')
    assert_equal 3, groups.size
  end

  def test_unknown_group
    refute @ldap.group("cn=foobar,ou=groups,dc=github,dc=com"),
      "Expected to not bind any group"
  end
end

class GitHubLdapLoopedGroupTest < GitHub::Ldap::Test
  def setup
    @group = GitHub::Ldap.new(options).group("cn=enterprise,ou=groups,dc=github,dc=com")
  end

  def test_members_from_subgroups
    assert_equal 4, @group.members.size
  end
end

class GitHubLdapMissingEntriesTest < GitHub::Ldap::Test
  def setup
    @ldap = GitHub::Ldap.new(options)
  end

  def test_load_right_members
    assert_equal 3, @ldap.domain("cn=spaniards,ou=groups,dc=github,dc=com").bind[:member].size
  end

  def test_ignore_missing_member_entries
    assert_equal 2, @ldap.group("cn=spaniards,ou=groups,dc=github,dc=com").members.size
  end
end
