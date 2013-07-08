module GitHub
  class Ldap
    # A domain represents the base object for an ldap tree.
    # It encapsulates the operations that you can perform against a tree, authenticating users, for instance.
    #
    # This makes possible to reuse a server connection to perform operations with two different domain bases.
    #
    # To get a domain, you'll need to create a `Ldap` object and then call the method `domain` with the name of the base.
    #
    # For example:
    #
    # domain = GitHub::Ldap.new(options).domain("dc=github,dc=com")
    #
    class Domain
      def initialize(base_name, connection, uid)
        @base_name, @connection, @uid = base_name, connection, uid
      end

      # Generate a filter to get the configured groups in the ldap server.
      # Takes the list of the group names and generate a filter for the groups
      # with cn that match and also include members:
      #
      # group_names: is an array of group CNs.
      #
      # Returns the ldap filter.
      def group_filter(group_names)
        or_filters = group_names.map {|g| Net::LDAP::Filter.eq("cn", g)}.reduce(:|)
        Net::LDAP::Filter.pres("member") & or_filters
      end

      # List the groups in the ldap server that match the configured ones.
      #
      # group_names: is an array of group CNs.
      #
      # Returns a list of ldap entries for the configured groups.
      def groups(group_names)
        filter = group_filter(group_names)

        @connection.search(base: @base_name,
          attributes: %w{ou cn dn sAMAccountName member},
          filter: filter)
      end

      # List the groups that a user is member of.
      #
      # user_dn: is the dn for the user ldap entry.
      # group_names: is an array of group CNs.
      #
      # Return an Array with the groups that the given user is member of that belong to the given group list.
      def membership(user_dn, group_names)
        or_filters    = group_names.map {|g| Net::LDAP::Filter.eq("cn", g)}.reduce(:|)
        member_filter = Net::LDAP::Filter.eq("member", user_dn) & or_filters

        @connection.search(base: @base_name,
          attributes: %w{ou cn dn sAMAccountName member},
          filter: member_filter)
      end

      # Check if the user is include in any of the configured groups.
      #
      # user_dn: is the dn for the user ldap entry.
      # group_names: is an array of group CNs.
      #
      # Returns true if the user belongs to any of the groups.
      # Returns false otherwise.
      def is_member?(user_dn, group_names)
        return true if group_names.nil?
        return true if group_names.empty?

        user_membership = membership(user_dn, group_names)

        !user_membership.empty?
      end

      # Check if the user credentials are valid.
      #
      # login: is the user's login.
      # password: is the user's password.
      #
      # Returns a Ldap::Entry if the credentials are valid.
      # Returns nil if the credentials are invalid.
      def valid_login?(login, password)
        result = @connection.bind_as(
          base:     @base_name,
          limit:    1,
          filter:   Net::LDAP::Filter.eq(@uid, login),
          password: password)

        return result.first if result.is_a?(Array)
      end

      # Authenticate a user with the ldap server.
      #
      # login: is the user's login. This method doesn't accept email identifications.
      # password: is the user's password.
      # group_names: is an array of group CNs.
      #
      # Returns the user info if the credentials are valid and there are no groups configured.
      # Returns the user info if the credentials are valid and the user belongs to a configured group.
      # Returns nil if the credentials are invalid
      def authenticate!(login, password, group_names = nil)
        user = valid_login?(login, password)

        return user if user && is_member?(user.dn, group_names)
      end
    end
  end
end
