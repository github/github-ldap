require_relative '../test_helper'

class GitHubLdapRecursiveMembersTest < GitHub::Ldap::Test
  def setup
    @ldap     = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain   = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @strategy = GitHub::Ldap::Members::Recursive.new(@ldap)
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
end
