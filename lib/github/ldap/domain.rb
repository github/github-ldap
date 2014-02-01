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
      include Filter

      def initialize(base_name, connection, uid)
        @base_name, @connection, @uid = base_name, connection, uid
      end

      # List the groups in the ldap server that match the configured ones.
      #
      # group_names: is an array of group CNs.
      #
      # Returns a list of ldap entries for the configured groups.
      def groups(group_names)
        search(filter: group_filter(group_names))
      end

      # List the groups that a user is member of.
      #
      # user_dn: is the dn for the user ldap entry.
      # group_names: is an array of group CNs.
      #
      # Return an Array with the groups that the given user is member of that belong to the given group list.
      def membership(user_dn, group_names)
        search(filter: group_filter(group_names, user_dn))
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
        if user = user?(login) and auth(user, password)
          return user
        end
      end

      # Check if a user exists based in the `uid`.
      #
      # login: is the user's login
      #
      # Returns the user if the login matches any `uid`.
      # Returns nil if there are no matches.
      def user?(login)
        escaped_login = Net::LDAP::Filter.escape(login)
        rs = search(
          filter: Net::LDAP::Filter.eq(@uid, escaped_login),
          attributes: [],
          limit: 1)
        rs and rs.first
      end

      # Check if a user can be bound with a password.
      #
      # user: is a ldap entry representing the user.
      # password: is the user's password.
      #
      # Returns true if the user can be bound.
      def auth(user, password)
        @connection.bind(method: :simple, username: user.dn, password: password)
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

      # Search entries using this domain as base.
      #
      # options: is a Hash with the options for the search.
      # The base option is always overriden.
      #
      # Returns an array with the entries found.
      # Returns nil if there are no entries.
      def search(options)
        options[:base] = @base_name
        options[:attributes] ||= %w{ou cn dn sAMAccountName member uniqueMember}
        options[:ignore_server_caps] ||= true
        options[:paged_searches_supported] ||= true

        @connection.search(options)
      end

      # Provide a meaningful result after a protocol operation (for example,
      # bind or search) has completed.
      #
      # Returns an OpenStruct containing an LDAP result code and a
      # human-readable string.
      # See http://tools.ietf.org/html/rfc4511#appendix-A
      def get_operation_result
        @connection.get_operation_result
      end
    end
  end
end
