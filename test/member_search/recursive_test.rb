require_relative '../test_helper'

class GitHubLdapRecursiveMemberSearchTest < GitHub::Ldap::Test
  def setup
    @ldap     = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain   = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @strategy = GitHub::Ldap::MemberSearch::Recursive.new(@ldap)
  end

  def find_group(cn)
    @domain.groups([cn]).first
  end

  def test_finds_group_members
    members = @strategy.perform(find_group("nested-group1")).map(&:dn)
    assert_includes members, @entry.dn
  end

  def test_finds_nested_group_members
    members = @strategy.perform(find_group("n-depth-nested-group1")).map(&:dn)
    assert_includes members, @entry.dn
  end

  def test_finds_deeply_nested_group_members
    members = @strategy.perform(find_group("n-depth-nested-group9")).map(&:dn)
    assert_includes members, @entry.dn
  end

  def test_finds_posix_group_members
    members = @strategy.perform(find_group("posix-group1")).map(&:dn)
    assert_includes members, @entry.dn
  end

  def test_excludes_nonmembers
    members = @strategy.perform(find_group("n-depth-nested-group1")).map(&:dn)

    # entry not in any group
    refute_includes members, "uid=groupless-user1,ou=People,dc=github,dc=com"

    # entry in an unrelated group
    refute_includes members, "uid=admin1,ou=People,dc=github,dc=com"
  end

  def test_respects_configured_depth_limit
    strategy = GitHub::Ldap::MemberSearch::Recursive.new(@ldap, depth: 2)
    members = strategy.perform(find_group("n-depth-nested-group9")).map(&:dn)
    refute_includes members, @entry.dn
  end
end
