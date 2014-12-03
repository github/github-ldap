require_relative '../test_helper'

class GitHubLdapClassicMemberOfTest < GitHub::Ldap::Test
  def setup
    @ldap     = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain   = @ldap.domain("dc=github,dc=com")
    @entry    = @domain.user?('user1')
    @strategy = GitHub::Ldap::MemberOf::Classic.new(@ldap)
  end

  def find_group(cn)
    @domain.groups([cn]).first
  end

  def test_finds_groups_entry_is_a_direct_member_of
    member_of = @strategy.perform(@entry)
    assert_includes member_of.map(&:dn), find_group("nested-group1").dn
  end

  def test_finds_subgroups_entry_is_a_member_of
    skip "Classic strategy does not support nested subgroups"
    member_of = @strategy.perform(@entry)
    assert_includes member_of.map(&:dn), find_group("head-group").dn
    assert_includes member_of.map(&:dn), find_group("tail-group").dn
  end

  def test_excludes_groups_entry_is_not_a_member_of
    member_of = @strategy.perform(@entry)
    refute_includes member_of.map(&:dn), find_group("ghe-admins").dn
  end
end
