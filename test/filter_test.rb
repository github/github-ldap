require_relative 'test_helper'

class FilterTest < GitHub::Ldap::Test
  class Subject
    include GitHub::Ldap::Filter
    def initialize(ldap)
      @ldap = ldap
    end
  end

  # Fake a Net::LDAP::Entry
  class Entry < Struct.new(:dn, :uid)
    def [](field)
      Array(send(field))
    end
  end

  def setup
    @ldap    = GitHub::Ldap.new(options.merge(:uid => 'uid'))
    @subject = Subject.new(@ldap)
    @me      = 'uid=calavera,dc=github,dc=com'
    @uid     = "calavera"
    @entry   = Net::LDAP::Entry.new(@me)
    @entry[:uid] = @uid
  end

  def test_member_present
    assert_equal "(|(member=*)(uniqueMember=*))", @subject.member_filter.to_s
  end

  def test_member_equal
    assert_equal "(|(member=#{@me})(uniqueMember=#{@me}))",
                 @subject.member_filter(@entry).to_s
  end

  def test_member_equal_with_string
    assert_equal "(|(member=#{@me})(uniqueMember=#{@me}))",
                 @subject.member_filter(@entry.dn).to_s
  end

  def test_posix_member_without_uid
    @entry.uid = nil
    assert_nil @subject.posix_member_filter(@entry, @ldap.uid)
  end

  def test_posix_member_equal
    assert_equal "(memberUid=#{@uid})",
                 @subject.posix_member_filter(@entry, @ldap.uid).to_s
  end

  def test_posix_member_equal_string
    assert_equal "(memberUid=#{@uid})",
                 @subject.posix_member_filter(@uid).to_s
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
