require 'test_helper'

class FilterTest < Minitest::Test
  class Subject; include GitHub::Ldap::Filter; end

  def setup
    @subject = Subject.new
    @me = 'uid=calavera,dc=github,dc=com'
  end

  def test_member_present
    assert_equal "(member=*)", @subject.member_filter.to_s
  end

  def test_member_equal
    assert_equal "(member=#{@me})", @subject.member_filter(@me).to_s
  end

  def test_groups_reduced
    assert_equal "(&(member=*)(|(cn=Enterprise)(cn=People)))",
      @subject.group_filter(%w(Enterprise People)).to_s
  end

  def test_groups_for_member
    assert_equal "(&(member=#{@me})(|(cn=Enterprise)(cn=People)))",
      @subject.group_filter(%w(Enterprise People), @me).to_s
  end
end
