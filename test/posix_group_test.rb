require_relative 'test_helper'

class GitHubLdapPosixGroupTest < GitHub::Ldap::Test
  def setup
    @simple_group = Net::LDAP::Entry._load("""
dn: cn=simple-group,ou=Groups,dc=github,dc=com
cn: simple-group
objectClass: posixGroup
memberUid: user1
memberUid: user2""")

    @one_level_deep_group = Net::LDAP::Entry._load("""
dn: cn=one-level-deep-group,ou=Groups,dc=github,dc=com
cn: one-level-deep-group
objectClass: posixGroup
objectClass: groupOfNames
memberUid: user6
member: cn=ghe-users,ou=Groups,dc=github,dc=com""")

    @two_levels_deep_group = Net::LDAP::Entry._load("""
dn: cn=two-levels-deep-group,ou=Groups,dc=github,dc=com
cn: two-levels-deep-group
objectClass: posixGroup
objectClass: groupOfNames
memberUid: user6
member: cn=n-depth-nested-group2,ou=Groups,dc=github,dc=com
member: cn=posix-group1,ou=Groups,dc=github,dc=com""")

    @empty_group = Net::LDAP::Entry._load("""
dn: cn=empty-group,ou=Groups,dc=github,dc=com
cn: empty-group
objectClass: posixGroup""")

    @ldap = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
  end

  def test_posix_group
    entry = @ldap.search(filter: "(cn=posix-group1)").first
    assert GitHub::Ldap::PosixGroup.valid?(entry),
      "Expected entry to be a valid posixGroup"
  end

  def test_posix_simple_members
    assert group = @ldap.group("cn=posix-group1,ou=Groups,dc=github,dc=com")
    members = group.members

    assert_equal 5, members.size
    assert_equal %w(user1 user2 user3 user4 user5), members.map(&:uid).flatten.sort
  end

  def test_posix_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    members = group.members

    assert_equal 3, members.size
  end

  def test_posix_combined_group_unique_members
    group = GitHub::Ldap::PosixGroup.new(@ldap, @two_levels_deep_group)
    members = group.members

    assert_equal 10, members.size
  end

  def test_empty_subgroups
    group = GitHub::Ldap::PosixGroup.new(@ldap, @simple_group)
    subgroups = group.subgroups

    assert subgroups.empty?, "Simple posixgroup expected to not have subgroups"
  end

  def test_posix_combined_group_subgroups
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    subgroups = group.subgroups

    assert_equal 1, subgroups.size
  end

  def test_is_member_simple_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @simple_group)
    user  = @ldap.domain("uid=user1,ou=People,dc=github,dc=com").bind

    assert group.is_member?(user),
      "Expected user in the memberUid list to be a member of the posixgroup"
  end

  def test_is_member_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    user  = @ldap.domain("uid=user1,ou=People,dc=github,dc=com").bind

    assert group.is_member?(user),
      "Expected user in a subgroup to be a member of the posixgroup"
  end

  def test_is_not_member_simple_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @simple_group)
    user  = @ldap.domain("uid=user10,ou=People,dc=github,dc=com").bind

    refute group.is_member?(user),
      "Expected user to not be member when her uid is not in the list of memberUid"
  end

  def test_is_member_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    user  = @ldap.domain("uid=user10,ou=People,dc=github,dc=com").bind

    refute group.is_member?(user),
      "Expected user to not be member when she's not member of any subgroup"
  end

  def test_empty_posix_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @empty_group)

    assert group.members.empty?,
      "Expected members to be an empty array"
  end
end
