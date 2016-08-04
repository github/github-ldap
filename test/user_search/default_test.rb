require_relative '../test_helper'

class GitHubLdapActiveDirectoryUserSearchTests < GitHub::Ldap::Test
  def setup
    @ldap = GitHub::Ldap.new(options)
    @default_user_search = GitHub::Ldap::UserSearch::Default.new(@ldap)
  end

  def test_default_search_options
    @ldap.expects(:search).with(has_entries(
      attributes: [],
      size: 1,
      paged_searches_supported: true,
      base: "CN=HI,CN=McDunnough",
      filter: kind_of(Net::LDAP::Filter)
    ))
    @default_user_search.perform("","CN=HI,CN=McDunnough","",{})
  end
end
