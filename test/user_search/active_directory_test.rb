require_relative '../test_helper'

class GitHubLdapActiveDirectoryUserSearchTests < GitHub::Ldap::Test

  def test_global_catalog_returns_empty_array_for_no_results
    ldap = GitHub::Ldap.new(options.merge(host: 'ghe.dev'))
    ad_user_search = GitHub::Ldap::UserSearch::ActiveDirectory.new(ldap)

    mock_global_catalog_connection = mock("GitHub::Ldap::UserSearch::GlobalCatalog")
    mock_global_catalog_connection.expects(:search).returns(nil)
    ad_user_search.expects(:global_catalog_connection).returns(mock_global_catalog_connection)
    results = ad_user_search.perform("login", "CN=Joe", "uid", {})
    assert_equal [], results
  end

  def test_global_catalog_returns_array_of_results
    ldap = GitHub::Ldap.new(options.merge(host: 'ghe.dev'))
    ad_user_search = GitHub::Ldap::UserSearch::ActiveDirectory.new(ldap)

    mock_global_catalog_connection = mock("GitHub::Ldap::UserSearch::GlobalCatalog")
    stub_entry = mock("Net::LDAP::Entry")

    mock_global_catalog_connection.expects(:search).returns(stub_entry)
    ad_user_search.expects(:global_catalog_connection).returns(mock_global_catalog_connection)

    results = ad_user_search.perform("login", "CN=Joe", "uid", {})
    assert_equal [stub_entry], results
  end

  def test_searches_with_empty_base_dn
    ldap = GitHub::Ldap.new(options.merge(host: 'ghe.dev'))
    ad_user_search = GitHub::Ldap::UserSearch::ActiveDirectory.new(ldap)

    mock_global_catalog_connection = mock("GitHub::Ldap::UserSearch::GlobalCatalog")
    mock_global_catalog_connection.expects(:search).with(has_entry(:base => ""))
    ad_user_search.expects(:global_catalog_connection).returns(mock_global_catalog_connection)
    ad_user_search.perform("login", "CN=Joe", "uid", {})
  end

  def test_global_catalog_default_settings
    ldap = GitHub::Ldap.new(options.merge(host: 'ghe.dev'))
    global_catalog = GitHub::Ldap::UserSearch::GlobalCatalog.connection(ldap)
    instrumentation_service = global_catalog.instance_variable_get(:@instrumentation_service)

    auth = global_catalog.instance_variable_get(:@auth)
    assert_equal :simple, auth[:method]
    assert_equal "uid=admin,dc=github,dc=com", auth[:username]
    assert_equal "passworD1", auth[:password]
    assert_equal "ghe.dev", global_catalog.host
    assert_equal 3268, global_catalog.port
    assert_equal "MockInstrumentationService", instrumentation_service.class.name
  end
end
