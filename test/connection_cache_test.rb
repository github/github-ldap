require_relative 'test_helper'

class GitHubLdapConnectionCacheTestCases < GitHub::Ldap::Test

  def setup
    mock_ldap = mock("GitHub::Ldap")
    GitHub::Ldap.stubs(:new).returns(mock_ldap)
  end

  def test_returns_cached_connection
    conn1 = GitHub::Ldap::ConnectionCache.get_connection({:host => "ghe.gh"})
    conn2 = GitHub::Ldap::ConnectionCache.get_connection({:host => "ghe.gh"})
    assert_equal conn1.object_id, conn2.object_id
  end

  def test_creates_new_connections_per_host
    conn1 = GitHub::Ldap::ConnectionCache.get_connection({:host => "ghe.gh"})
    conn2 = GitHub::Ldap::ConnectionCache.get_connection({:host => "ghe.dev"})
    conn3 = GitHub::Ldap::ConnectionCache.get_connection({:host => "ghe.dev"})
    refute_equal conn1.object_id, conn2.object_id
    assert_equal conn2.object_id, conn3.object_id
  end
end
