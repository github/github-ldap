require_relative 'test_helper'

class GitHubLdapForestSearchTest < GitHub::Ldap::Test
  def setup
    @connection = Net::LDAP.new({
      host: options[:host],
      port: options[:port],
      instrumentation_service: options[:instrumentation_service]
    })
    #@connection.stub(:search, {}, ['search-forest'])
    @forest_search = GitHub::Ldap::ForestSearch.new(@connection, "naming")
  end

  def test_search
    @forest_search.search({})
    assert true
  end
end
