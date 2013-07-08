module GitHub
  class Ldap
    require 'net/ldap'

    def initialize(options = {})
      @user_domain = options[:user_domain]
      @uid         = options[:uid] || "sAMAccountName"

      @ldap = Net::LDAP.new({
        host: options[:host],
        port: options[:port]
      })

      @ldap.authenticate(options[:admin_user], options[:admin_password])

      if encryption = check_encryption(options[:encryptation])
        @ldap.encryption(encryption)
      end
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

      @ldap.search(base: @user_domain,
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

       @ldap.search(base: @user_domain,
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
      result = @ldap.bind_as(
        base:     @user_domain,
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

    # Check the legacy auth configuration options (before David's war with omniauth)
    # to determine whether to use encryptation or not.
    #
    # encryptation: is the encryptation method, either 'ssl', 'tls', 'simple_tls' or 'start_tls'.
    #
    # Returns the real encryptation type.
    def check_encryption(encryption)
      return unless encryption

      case encryption.downcase.to_sym
      when :ssl, :simple_tls
        :simple_tls
      when :tls, :start_tls
        :start_tls
      end
    end

    # Utility method to check if the connection with the server can be stablished.
    # It tries to bind with the ldap auth default configuration.
    #
    # Return true if the connection is successful.
    # Return false if the authentication settings are not valid.
    # Raises an Net::LDAP::LdapError if the connection fails.
    def test_connection
      @ldap.bind
    end
  end
end
