require 'test_helper'

class GitHubLdapPosixGroupTest < GitHub::Ldap::Test
  def self.test_server_options
    {user_fixtures: FIXTURES.join('github-with-subgroups.ldif').to_s}
  end

  def setup
    @simple_group = Net::LDAP::Entry._load("""
dn: cn=enterprise-posix-devs,ou=groups,dc=github,dc=com
cn: enterprise-posix-devs
objectClass: posixGroup
memberUid: benburkert
memberUid: mtodd""")

    @one_level_deep_group = Net::LDAP::Entry._load("""
dn: cn=enterprise-posix-ops,ou=groups,dc=github,dc=com
cn: enterprise-posix-ops
objectClass: posixGroup
objectClass: groupOfNames
memberUid: sbryant
member: cn=spaniards,ou=groups,dc=github,dc=com""")

    @two_levels_deep_group = Net::LDAP::Entry._load("""
dn: cn=enterprise-posix,ou=groups,dc=github,dc=com
cn: Enterprise Posix
objectClass: posixGroup
objectClass: groupOfNames
memberUid: calavera
member: cn=enterprise-devs,ou=groups,dc=github,dc=com
member: cn=enterprise-ops,ou=groups,dc=github,dc=com""")

    @empty_group = Net::LDAP::Entry._load("""
dn: cn=enterprise-posix-empty,ou=groups,dc=github,dc=com
cn: enterprise-posix-empty
objectClass: posixGroup""")

    @ldap = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
  end

  def test_posix_group
    assert GitHub::Ldap::PosixGroup.valid?(@simple_group),
      "Expected entry to be a valid posixGroup"
  end

  def test_posix_simple_members
    group = GitHub::Ldap::PosixGroup.new(@ldap, @simple_group)
    members = group.members

    assert_equal 2, members.size
    assert_equal 'benburkert', members.first[:uid].first
  end

  def test_posix_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    members = group.members

    assert_equal 3, members.size
  end

  def test_posix_combined_group_unique_members
    group = GitHub::Ldap::PosixGroup.new(@ldap, @two_levels_deep_group)
    members = group.members

    assert_equal 4, members.size
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
    user  = @ldap.domain("uid=benburkert,ou=users,dc=github,dc=com").bind

    assert group.is_member?(user),
      "Expected user in the memberUid list to be a member of the posixgroup"
  end

  def test_is_member_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    user  = @ldap.domain("uid=calavera,ou=users,dc=github,dc=com").bind

    assert group.is_member?(user),
      "Expected user in a subgroup to be a member of the posixgroup"
  end

  def test_is_not_member_simple_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @simple_group)
    user  = @ldap.domain("uid=calavera,ou=users,dc=github,dc=com").bind

    refute group.is_member?(user),
      "Expected user to not be member when her uid is not in the list of memberUid"
  end

  def test_is_member_combined_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @one_level_deep_group)
    user  = @ldap.domain("uid=benburkert,ou=users,dc=github,dc=com").bind

    refute group.is_member?(user),
      "Expected user to not be member when she's not member of any subgroup"
  end

  def test_empty_posix_group
    group = GitHub::Ldap::PosixGroup.new(@ldap, @empty_group)

    assert group.members.empty?,
      "Expected members to be an empty array"
  end
end
