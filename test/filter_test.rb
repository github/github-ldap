require 'test_helper'

class FilterTest < Minitest::Test
  class Subject; include GitHub::Ldap::Filter; end

  def setup
    @subject = Subject.new
    @me = 'uid=calavera,dc=github,dc=com'
  end

  def test_member_present
    assert_equal "(|(member=*)(uniqueMember=*))", @subject.member_filter.to_s
  end

  def test_member_equal
    assert_equal "(|(member=#{@me})(uniqueMember=#{@me}))", @subject.member_filter(@me).to_s
  end

  def test_groups_reduced
    assert_equal "(|(cn=Enterprise)(cn=People))",
      @subject.group_filter(%w(Enterprise People)).to_s
  end

  def test_members_of_group
    assert_equal "(memberOf=cn=group,dc=github,dc=com)",
      @subject.members_of_group('cn=group,dc=github,dc=com').to_s

    assert_equal "(isMemberOf=cn=group,dc=github,dc=com)",
      @subject.members_of_group('cn=group,dc=github,dc=com', 'isMemberOf').to_s
  end

  def test_subgroups_of_group
    assert_equal "(&(memberOf=cn=group,dc=github,dc=com)#{Subject::ALL_GROUPS_FILTER})",
      @subject.subgroups_of_group('cn=group,dc=github,dc=com').to_s

    assert_equal "(&(isMemberOf=cn=group,dc=github,dc=com)#{Subject::ALL_GROUPS_FILTER})",
      @subject.subgroups_of_group('cn=group,dc=github,dc=com', 'isMemberOf').to_s
  end

  def test_all_members_by_uid
    assert_equal "(|(uid=calavera)(uid=mtodd))",
      @subject.all_members_by_uid(%w(calavera mtodd), :uid).to_s
  end
end
