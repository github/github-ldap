module GitHub
  class Ldap
    # This class represents a POSIX group.
    #
    # To get a POSIX group, you'll need to create a `Ldap` object and then call the method `group`.
    # The parameter for `group` must be a dn to a group entry with `posixGroup` amongs the values for the attribute `objectClass`.
    #
    # For example:
    #
    # domain = GitHub::Ldap.new(options).group("cn=enterprise,dc=github,dc=com")
    #
    class PosixGroup < Group
      # Public - Check if an ldap entry is a valid posixGroup.
      #
      # entry: is the ldap entry to check.
      #
      # Returns true if the entry includes the objectClass `posixGroup`.
      def self.valid?(entry)
        entry[:objectClass].any? {|oc| oc.downcase == 'posixgroup'}
      end

      # Public - Overrides Group#members
      #
      # Search the entries corresponding to the members in the `memberUid` attribute.
      # It calls `super` if the group entry includes `member` or `uniqueMember`.
      #
      # Returns an array with the members of this group and its submembers if there is any.
      def members
        return @all_posix_members if @all_posix_members

        @all_posix_members = search_members_by_uids
        @all_posix_members.concat super if combined_group?

        @all_posix_members.uniq! {|m| m.dn }
        @all_posix_members
      end

      # Public - Overrides Group#subgroups
      #
      # Prevent to call super when the group entry does not include `member` or `uniqueMember`.
      #
      # Returns an array with the subgroups of this group.
      def subgroups
        return [] unless combined_group?

        super
      end

      # Public - Overrides Group#is_member?
      #
      # Chech if the user entry uid exists in the collection of `memberUid`.
      # It calls `super` if the group entry includes `member` or `uniqueMember`.
      #
      # Return true if the user is member if this group or any subgroup.
      def is_member?(user_entry)
        entry_uids = user_entry[ldap.uid]
        return true if !(entry_uids & entry[:memberUid]).empty?

        super if combined_group?
      end

      # Internal - Check if this posix group also includes `member` and `uniqueMember` entries.
      #
      # Returns true if any of the membership names is include in this group entry.
      def combined_group?
        MEMBERSHIP_NAMES.any? {|name| !entry[name].empty? }
      end

      # Internal - Search all members by uid.
      #
      # Return an array of user entries.
      def search_members_by_uids
        member_uids = entry[:memberUid]
        return [] if member_uids.empty?

        filter = all_members_by_uid(member_uids, ldap.uid)
        ldap.search(filter: filter)
      end
    end
  end
end
