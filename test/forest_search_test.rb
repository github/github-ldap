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

  def test_uses_connection_search_when_no_forest_present
    # First search returns an empty Hash of domain controllers
    @connection.expects(:search).returns({})
    # Since the forest is empty, should fall back on the base connection
    @connection.expects(:search)
    @forest_search.search({})
  end

  def test_uses_connection_search_when_domains_nil
    # First search returns nil
    @connection.expects(:search).returns(nil)
    # Since the forest is empty, should fall back on the base connection
    @connection.expects(:search)
    @forest_search.search({})
  end

  def test_iterates_over_domain_controllers_when_forest_present
    mock_domains = Object.new
    mock_domain_controller = Object.new

    # Mock out two Domain Controller connections (Net::LDAP objects)
    mock_dc_connection1 = Object.new
    mock_dc_connection2 = Object.new
    rootdn = "DC=ad,DC=ghe,DC=local"
    # Create a mock forest that contains the two mock DCs
    # This assumes a single-l
    forest = [[rootdn, mock_dc_connection1],[rootdn, mock_dc_connection2]]

    # First search returns the Hash of domain controllers
    # This is what the forest is built from.
    @connection.expects(:search).returns(mock_domains)
    mock_domains.expects(:each_with_object).returns(forest)

    # Then we expect that a search will be performed on the LDAP object
    # created from the returned forest of domain controllers
    mock_dc_connection1.expects(:search)
    mock_dc_connection2.expects(:search)
    base = "CN=user1,CN=Users,DC=ad,DC=ghe,DC=local"
    @forest_search.search({:base => base})
  end

  def test_returns_concatenated_search_results_from_forest
    mock_domains = Object.new
    mock_domain_controller = Object.new

    mock_dc_connection1 = Object.new
    mock_dc_connection2 = Object.new
    rootdn = "DC=ad,DC=ghe,DC=local"
    forest = [[rootdn, mock_dc_connection1],[rootdn, mock_dc_connection2]]

    @connection.expects(:search).returns(mock_domains)
    mock_domains.expects(:each_with_object).returns(forest)

    mock_dc_connection1.expects(:search).returns(["entry1"])
    mock_dc_connection2.expects(:search).returns(["entry2"])
    base = "CN=user1,CN=Users,DC=ad,DC=ghe,DC=local"
    results = @forest_search.search({:base => base})
    assert_equal results, ["entry1", "entry2"]
  end

end
