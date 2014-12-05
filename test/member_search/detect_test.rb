require_relative '../test_helper'

# NOTE: Since this strategy is targeted at detecting ActiveDirectory
# capabilities, and we don't have AD setup in CI, we stub out actual queries
# and test against what AD *would* respond with.

class GitHubLdapDetectMemberSearchTest < GitHub::Ldap::Test
  include GitHub::Ldap::Capabilities

  def setup
    @ldap      = GitHub::Ldap.new(options.merge(search_domains: %w(dc=github,dc=com)))
    @domain    = @ldap.domain("dc=github,dc=com")
    @entry     = @domain.user?('user1')
    @strategy  = GitHub::Ldap::MemberSearch::Detect.new(@ldap)
  end

  def test_defers_to_configured_strategy
    @ldap.configure_member_search_strategy(:classic)

    assert_kind_of GitHub::Ldap::MemberSearch::Classic, @strategy.strategy
  end

  def test_detects_active_directory
    caps = Net::LDAP::Entry.new
    caps[:supportedcapabilities] = [ACTIVE_DIRECTORY_V61_R2_OID]

    @ldap.stub :capabilities, caps do
      assert_kind_of GitHub::Ldap::MemberSearch::ActiveDirectory,
      @strategy.strategy
    end
  end

  def test_falls_back_to_recursive
    caps = Net::LDAP::Entry.new
    caps[:supportedcapabilities] = []

    @ldap.stub :capabilities, caps do
      assert_kind_of GitHub::Ldap::MemberSearch::Recursive,
      @strategy.strategy
    end
  end
end
