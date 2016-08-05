require_relative 'test_helper'

class GitHubLdapConnectionCacheTestCases < GitHub::Ldap::Test

  def test_returns_cached_connection
    conn1 = GitHub::Ldap::ConnectionCache.get_connection(options.merge(:host => "ad1.ghe.dev"))
    conn2 = GitHub::Ldap::ConnectionCache.get_connection(options.merge(:host => "ad1.ghe.dev"))
    assert_equal conn1.object_id, conn2.object_id
  end

  def test_creates_new_connections_per_host
    conn1 = GitHub::Ldap::ConnectionCache.get_connection(options.merge(:host => "ad1.ghe.dev"))
    conn2 = GitHub::Ldap::ConnectionCache.get_connection(options.merge(:host => "ad2.ghe.dev"))
    conn3 = GitHub::Ldap::ConnectionCache.get_connection(options.merge(:host => "ad2.ghe.dev"))
    refute_equal conn1.object_id, conn2.object_id
    assert_equal conn2.object_id, conn3.object_id
  end
end
