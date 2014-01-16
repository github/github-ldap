module GitHub
  class Ldap
    module Filter
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
    end
  end
end
