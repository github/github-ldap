require_relative 'test_helper'

class GitHubLdapReferralChaserTestCases < GitHub::Ldap::Test

  def setup
    @ldap = GitHub::Ldap.new(options)
    @chaser = GitHub::Ldap::ReferralChaser.new(@ldap)
  end

  def test_creates_referral_with_connection_credentials
    @ldap.expects(:search).yields({ search_referrals: ["ldap://dc1.ghe.local/"]}).returns([])

    referral = mock("GitHub::Ldap::ReferralChaser::Referral")
    referral.stubs(:search).returns([])

    GitHub::Ldap::ReferralChaser::Referral.expects(:new)
      .with("ldap://dc1.ghe.local/", "uid=admin,dc=github,dc=com", "passworD1", options[:port])
      .returns(referral)

    @chaser.search({})
  end

  def test_creates_referral_with_default_port
    @ldap.expects(:search).yields({
      search_referrals: ["ldap://dc1.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]
    }).returns([])

    stub_referral_connection = mock("GitHub::Ldap")
    stub_referral_connection.stubs(:search).returns([])
    GitHub::Ldap::ConnectionCache.expects(:get_connection).with(has_entry(port: options[:port])).returns(stub_referral_connection)
    chaser = GitHub::Ldap::ReferralChaser.new(@ldap)
    chaser.search({})
  end

  def test_creates_referral_for_first_referral_string
    @ldap.expects(:search).multiple_yields([
      { search_referrals:
        ["ldap://dc1.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local",
         "ldap://dc2.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]
      }
    ],[
      { search_referrals:
        ["ldap://dc3.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local",
         "ldap://dc4.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]
      }
    ]).returns([])

    referral = mock("GitHub::Ldap::ReferralChaser::Referral")
    referral.stubs(:search).returns([])

    GitHub::Ldap::ReferralChaser::Referral.expects(:new)
      .with(
        "ldap://dc1.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local",
        "uid=admin,dc=github,dc=com",
        "passworD1",
        options[:port])
      .returns(referral)

    @chaser.search({})
  end

  def test_returns_referral_search_results
    @ldap.expects(:search).multiple_yields([
      { search_referrals:
        ["ldap://dc1.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local",
         "ldap://dc2.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]
      }
    ],[
      { search_referrals:
        ["ldap://dc3.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local",
         "ldap://dc4.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]
      }
    ]).returns([])

    referral = mock("GitHub::Ldap::ReferralChaser::Referral")
    referral.expects(:search).returns(["result", "result"])

    GitHub::Ldap::ReferralChaser::Referral.expects(:new).returns(referral)

    results = @chaser.search({})
    assert_equal(["result", "result"], results)
  end

  def test_handle_blank_url_string_in_referral
    @ldap.expects(:search).yields({ search_referrals: [""] })

    results = @chaser.search({})
    assert_equal([], results)
  end

  def test_returns_referral_search_results
    @ldap.expects(:search).yields({ foo: ["not a referral"] })

    GitHub::Ldap::ReferralChaser::Referral.expects(:new).never
    results = @chaser.search({})
  end

  def test_referral_should_use_host_from_referral_string
    GitHub::Ldap::ConnectionCache.expects(:get_connection).with(has_entry(host: "dc4.ghe.local"))
    GitHub::Ldap::ReferralChaser::Referral.new("ldap://dc4.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local", "", "")
  end
end
