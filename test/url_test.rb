require_relative 'test_helper'

class GitHubLdapURLTestCases < GitHub::Ldap::Test

  def setup
    @url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local:123/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local?cn,mail,telephoneNumber?base?(cn=Charlie)")
  end

  def test_host
    assert_equal "dc4.ghe.local", @url.host
  end

  def test_port
    assert_equal 123, @url.port
  end

  def test_scheme
    assert_equal "ldap", @url.scheme
  end

  def test_default_port
    url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local?attributes?scope?filter")
    assert_equal 389, url.port
  end

  def test_simple_url
    url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local")
    assert_equal 389, url.port
    assert_equal "dc4.ghe.local", url.host
    assert_equal "ldap", url.scheme
    assert_equal "", url.dn
    assert_equal nil, url.attributes
    assert_equal nil, url.filter
    assert_equal nil, url.scope
  end

  def test_invalid_scheme
    ex = assert_raises(GitHub::Ldap::URL::InvalidLdapURLException) do
      GitHub::Ldap::URL.new("http://dc4.ghe.local")
    end
    assert_equal("Invalid LDAP URL: http://dc4.ghe.local", ex.message)
  end

  def test_invalid_url
    ex = assert_raises(GitHub::Ldap::URL::InvalidLdapURLException) do
      GitHub::Ldap::URL.new("not a url")
    end
    assert_equal("Invalid LDAP URL: not a url", ex.message)
  end

  def test_parse_dn
    assert_equal "CN=Maggie Mae,CN=Users,DC=dc4,DC=ghe,DC=local", @url.dn
  end

  def test_parse_attributes
    assert_equal "cn,mail,telephoneNumber", @url.attributes
  end

  def test_parse_filter
    assert_equal "(cn=Charlie)", @url.filter
  end

  def test_parse_scope
    assert_equal "base", @url.scope
  end

  def test_default_scope
    url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local/base_dn?cn=joe??filter")
    assert_equal "", url.scope
  end

  def test_net_ldap_scopes
    sub_scope_url = GitHub::Ldap::URL.new("ldap://ghe.local/base_dn?cn=joe?sub?filter")
    one_scope_url = GitHub::Ldap::URL.new("ldap://ghe.local/base_dn?cn=joe?one?filter")
    base_scope_url = GitHub::Ldap::URL.new("ldap://ghe.local/base_dn?cn=joe?base?filter")
    default_scope_url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local/base_dn?cn=joe??filter")
    invalid_scope_url = GitHub::Ldap::URL.new("ldap://dc4.ghe.local/base_dn?cn=joe?invalid?filter")

    assert_equal Net::LDAP::SearchScope_BaseObject, base_scope_url.net_ldap_scope
    assert_equal Net::LDAP::SearchScope_SingleLevel, one_scope_url.net_ldap_scope
    assert_equal Net::LDAP::SearchScope_WholeSubtree, sub_scope_url.net_ldap_scope
    assert_equal Net::LDAP::SearchScope_BaseObject, default_scope_url.net_ldap_scope
    assert_equal Net::LDAP::SearchScope_BaseObject, invalid_scope_url.net_ldap_scope
  end
end
