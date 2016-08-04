require_relative '../test_helper'
require 'mocha/mini_test'

class GitHubLdapActiveDirectoryUserSearchTests < GitHub::Ldap::Test

  def setup
    @ldap = GitHub::Ldap.new(options)
    @ad_user_search = GitHub::Ldap::UserSearch::ActiveDirectory.new(@ldap)
  end

  def test_global_catalog_returns_empty_array_for_no_results
    mock_global_catalog_connection = Object.new
    mock_global_catalog_connection.expects(:search).returns(nil)
    Net::LDAP.expects(:new).returns(mock_global_catalog_connection)
    results = @ad_user_search.perform("login", "CN=Joe", "uid", {})
    assert_equal [], results
  end

  def test_global_catalog_returns_array_of_results
    mock_global_catalog_connection = Object.new
    stub_entry = Object.new
    mock_global_catalog_connection.expects(:search).returns(stub_entry)
    Net::LDAP.expects(:new).returns(mock_global_catalog_connection)
    results = @ad_user_search.perform("login", "CN=Joe", "uid", {})
    assert_equal [stub_entry], results
  end

  def test_searches_with_empty_base_dn
    mock_global_catalog_connection = Object.new
    mock_global_catalog_connection.expects(:search).with(has_entry(:base => ""))
    Net::LDAP.expects(:new).returns(mock_global_catalog_connection)
    @ad_user_search.perform("login", "CN=Joe", "uid", {})
  end

  def test_global_catalog_default_settings
    global_catalog = @ad_user_search.global_catalog_connection
    instrumentation_service = global_catalog.instance_variable_get(:@instrumentation_service)

    auth = global_catalog.instance_variable_get(:@auth)
    assert_equal :simple, auth[:method]
    assert_equal "127.0.0.1", global_catalog.host
    assert_equal 3268, global_catalog.port
    assert_equal "MockInstrumentationService", instrumentation_service.class.name
  end

  module GitHubLdapUnauthenticatedTestCases
    def test_global_catalog_unauthenticated_default_settings
      @ad_user_search.expects(:active_directory_capability?).returns(true)
      global_catalog = @ad_user_search.global_catalog_connection
      # this is ugly, but currently the only way to test Net::LDAP#auth values
      auth = global_catalog.instance_variable_get(:@auth)

      assert_equal nil, auth[:password]
      assert_equal nil, auth[:username]
    end
  end

  module GitHubLdapAuthenticatedTestCases
    def test_global_catalog_authenticated_default_settings
      @ad_user_search.expects(:active_directory_capability?).returns(true)
      global_catalog = @ad_user_search.global_catalog_connection
      # this is ugly, but currently the only way to test Net::LDAP#auth values
      auth = global_catalog.instance_variable_get(:@auth)

      assert_equal "passworD1", auth[:password]
      assert_equal "uid=admin,dc=github,dc=com", auth[:username]
    end
  end
end
