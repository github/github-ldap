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
    assert_equal "(&(|(member=*)(uniqueMember=*))(|(cn=Enterprise)(cn=People)))",
      @subject.group_filter(%w(Enterprise People)).to_s
  end

  def test_groups_for_member
    assert_equal "(&(|(member=#{@me})(uniqueMember=#{@me}))(|(cn=Enterprise)(cn=People)))",
      @subject.group_filter(%w(Enterprise People), @me).to_s
  end

  def test_is_member_of_group
    assert_equal "(memberOf=cn=group,dc=github,dc=com)",
      @subject.is_member_of_group('cn=group,dc=github,dc=com').to_s

    assert_equal "(isMemberOf=cn=group,dc=github,dc=com)",
      @subject.is_member_of_group('cn=group,dc=github,dc=com', 'isMemberOf').to_s
  end

  def test_is_subgroup_of_group
    assert_equal "(&(memberOf=cn=group,dc=github,dc=com)#{Subject::ALL_GROUPS_FILTER})",
      @subject.is_subgroup_of_group('cn=group,dc=github,dc=com').to_s

    assert_equal "(&(isMemberOf=cn=group,dc=github,dc=com)#{Subject::ALL_GROUPS_FILTER})",
      @subject.is_subgroup_of_group('cn=group,dc=github,dc=com', 'isMemberOf').to_s
  end
end
