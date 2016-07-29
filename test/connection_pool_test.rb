require_relative 'test_helper'

class GitHubLdapConnectionPoolTestCases < GitHub::Ldap::Test

  def test_get_connection
    conn = GitHub::Ldap::ConnectionPool.get_connection({:host => "host"})
    assert_equal GitHub::Ldap, conn.class
  end

  def test_returns_cached_connection
    conn1 = GitHub::Ldap::ConnectionPool.get_connection({:host => "ghe.local"})
    conn2 = GitHub::Ldap::ConnectionPool.get_connection({:host => "ghe.local"})
    assert_equal conn1.object_id, conn2.object_id
  end

  def test_creates_new_connections_per_host
    conn1 = GitHub::Ldap::ConnectionPool.get_connection({:host => "ghe.local"})
    conn2 = GitHub::Ldap::ConnectionPool.get_connection({:host => "ghe.dev"})
    conn3 = GitHub::Ldap::ConnectionPool.get_connection({:host => "ghe.dev"})
    refute_equal conn1.object_id, conn2.object_id
    assert_equal conn2.object_id, conn3.object_id
  end
end
