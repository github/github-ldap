module GitHub
  class Ldap
    module Filter
      ALL_GROUPS_FILTER = Net::LDAP::Filter.eq("objectClass", "groupOfNames") |
                          Net::LDAP::Filter.eq("objectClass", "groupOfUniqueNames")

      # Filter to get the configured groups in the ldap server.
      # Takes the list of the group names and generate a filter for the groups
      # with cn that match and also include members:
      #
      # group_names: is an array of group CNs.
      # user_dn: is an optional member to scope the search to.
      #
      # Returns a Net::LDAP::Filter.
      def group_filter(group_names, user_dn = nil)
        or_filters = group_names.map {|g| Net::LDAP::Filter.eq("cn", g)}.reduce(:|)
        member_filter(user_dn) & or_filters
      end

      # Filter to check a group membership.
      #
      # user_dn: is an optional user_dn to scope the search to.
      #
      # Returns a Net::LDAP::Filter.
      def member_filter(user_dn = nil)
        if user_dn
          Net::LDAP::Filter.eq("member", user_dn) | Net::LDAP::Filter.eq("uniqueMember", user_dn)
        else
          Net::LDAP::Filter.pres("member") | Net::LDAP::Filter.pres("uniqueMember")
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
    end
  end
end
