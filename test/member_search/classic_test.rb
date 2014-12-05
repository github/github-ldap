require_relative '../test_helper'

class GitHubLdapRecursiveMemberSearchTest < GitHub::Ldap::Test
  def setup
    @ldap     = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain   = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @strategy = GitHub::Ldap::MemberSearch::Classic.new(@ldap)
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

  def test_does_not_respect_configured_depth_limit
    strategy = GitHub::Ldap::MemberSearch::Classic.new(@ldap, depth: 2)
    members = strategy.perform(find_group("n-depth-nested-group9")).map(&:dn)
    assert_includes members, @entry.dn
  end
end
