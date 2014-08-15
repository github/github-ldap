module GitHub
  class Ldap
    module Filter
      ALL_GROUPS_FILTER = Net::LDAP::Filter.eq("objectClass", "groupOfNames") |
                          Net::LDAP::Filter.eq("objectClass", "groupOfUniqueNames") |
                          Net::LDAP::Filter.eq("objectClass", "posixGroup")

      MEMBERSHIP_NAMES  = %w(member uniqueMember)

      # Filter to get the configured groups in the ldap server.
      # Takes the list of the group names and generate a filter for the groups
      # with cn that match.
      #
      # group_names: is an array of group CNs.
      #
      # Returns a Net::LDAP::Filter.
      def group_filter(group_names)
        group_names.map {|g| Net::LDAP::Filter.eq("cn", g)}.reduce(:|)
      end

      # Filter to check a group membership.
      #
      # entry: is an optional Net::LDAP::Entry to scope the search to.
      #
      # Returns a Net::LDAP::Filter.
      def member_filter(entry = nil)
        if entry
          MEMBERSHIP_NAMES.map {|n| Net::LDAP::Filter.eq(n, entry.dn)}.reduce(:|)
        else
          MEMBERSHIP_NAMES.map {|n| Net::LDAP::Filter.pres(n)}.reduce(:|)
        end
      end

      # Filter to map a uid with a login.
      # It escapes the login before creating the filter.
      #
      # uid: the entry field to map.
      # login: the login to map.
      #
      # Returns a Net::LDAP::Filter.
      def login_filter(uid, login)
        Net::LDAP::Filter.eq(uid, Net::LDAP::Filter.escape(login))
      end

      # Filter groups that match a query cn.
      #
      # query: is a string to match the cn with.
      #
      # Returns a Net::LDAP::Filter.
      def group_contains_filter(query)
        Net::LDAP::Filter.contains("cn", query) & ALL_GROUPS_FILTER
      end

      # Filter to get all the members of a group using the virtual attribute `memberOf`.
      #
      # group_dn: is the group dn to look members for.
      # attr: is the membership attribute.
      #
      # Returns a Net::LDAP::Filter
      def members_of_group(group_dn, attr = 'memberOf')
        Net::LDAP::Filter.eq(attr, group_dn)
      end

      # Filter to get all the members of a group that are groups using the virtual attribute `memberOf`.
      #
      # group_dn: is the group dn to look members for.
      # attr: is the membership attribute.
      #
      # Returns a Net::LDAP::Filter
      def subgroups_of_group(group_dn, attr = 'memberOf')
        Net::LDAP::Filter.eq(attr, group_dn) & ALL_GROUPS_FILTER
      end

      # Filter to get all the members of a group which uid is included in `memberUid`.
      #
      # uids: is an array with all the uids to search.
      # uid_attr: is the names of the uid attribute in the directory.
      #
      # Returns a Net::LDAP::Filter
      def all_members_by_uid(uids, uid_attr)
        uids.map {|uid| Net::LDAP::Filter.eq(uid_attr, uid)}.reduce(:|)
      end
    end
  end
end
