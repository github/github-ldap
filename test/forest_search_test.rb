require_relative 'test_helper'
require 'mocha/mini_test'

class GitHubLdapForestSearchTest < GitHub::Ldap::Test
  def setup
    @connection = Net::LDAP.new({
      host: options[:host],
      port: options[:port],
      instrumentation_service: options[:instrumentation_service]
    })
    configuration_naming_context = "CN=Configuration,DC=ad,DC=ghe,DC=local"
    @forest_search = GitHub::Ldap::ForestSearch.new(@connection, configuration_naming_context)
  end

  def test_search
    @forest_search.search({})
    assert true
  end
end
