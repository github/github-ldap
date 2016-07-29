require_relative 'test_helper'

class GitHubLdapReferralChaserTestCases < GitHub::Ldap::Test

  def setup
    referral_entries = [
      {:search_referrals => ["ldap://dc4.ghe.local/CN=Maggie%20Mae,CN=Users,DC=dc4,DC=ghe,DC=local"]}
    ]
    @chaser = GitHub::Ldap::ReferralChaser.new(referral_entries, "admin1", "passworD1")
  end

  def test_creates_connection
    @chaser.with_referrals do |referral|
      assert_equal GitHub::Ldap, referral.connection.class
    end
  end

  def test_returns_url_escaped_search_base
    @chaser.with_referrals do |referral|
      assert_equal "CN=Maggie Mae,CN=Users,DC=dc4,DC=ghe,DC=local", referral.search_base
    end
  end

  def test_executes_for_every_entry
    referral_entries = [
      {:search_referrals => ["test1"]},
      {:search_referrals => ["test2"]}
    ]
    chaser = GitHub::Ldap::ReferralChaser.new(referral_entries, "admin1", "passworD1")

    called = 0
    chaser.with_referrals { called += 1 }
    assert_equal 2, called
  end

  def test_executes_for_every_referral
    referral_entries = [
      {:search_referrals => ["test1"]},
      {:search_referrals => ["test2", "test3"]}
    ]
    chaser = GitHub::Ldap::ReferralChaser.new(referral_entries, "admin1", "passworD1")

    called = 0
    chaser.with_referrals { called += 1 }
    assert_equal 3, called
  end
end
