require_relative '../test_helper'

class GitHubLdapActiveDirectoryMemberSearchStubbedTest < GitHub::Ldap::Test
  # Only run when AD integration tests aren't run
  def run(*)
    return super if self.class.test_env != "activedirectory"
    Minitest::Result.from(self)
  end

  def find_group(cn)
    @domain.groups([cn]).first
  end

  def setup
    @ldap     = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain   = @ldap.domain("dc=github,dc=com")
    @entry    = @domain.user?('user1')
    @strategy = GitHub::Ldap::MemberSearch::ActiveDirectory.new(@ldap)
  end

  def test_finds_group_members
    members =
      @ldap.stub :search, [@entry] do
        @strategy.perform(find_group("nested-group1")).map(&:dn)
      end
    assert_includes members, @entry.dn
  end

  def test_finds_nested_group_members
    members =
      @ldap.stub :search, [@entry] do
        @strategy.perform(find_group("n-depth-nested-group1")).map(&:dn)
      end
    assert_includes members, @entry.dn
  end

  def test_finds_deeply_nested_group_members
    members =
      @ldap.stub :search, [@entry] do
        @strategy.perform(find_group("n-depth-nested-group9")).map(&:dn)
      end
    assert_includes members, @entry.dn
  end
end

# See test/support/vm/activedirectory/README.md for details
class GitHubLdapActiveDirectoryMemberSearchIntegrationTest < GitHub::Ldap::Test
  # Only run this test suite if ActiveDirectory is configured
  def run(*)
    return super if self.class.test_env == "activedirectory"
    Minitest::Result.from(self)
  end

  def find_group(cn)
    @domain.groups([cn]).first
  end

  def setup
    @ldap     = GitHub::Ldap.new(options)
    @domain   = @ldap.domain(options[:search_domains])
    @entry    = @domain.user?('user1')
    @strategy = GitHub::Ldap::MemberSearch::ActiveDirectory.new(@ldap)
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
end
