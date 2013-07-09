module GitHub
  class Ldap
    require 'net/ldap'
    require 'github/ldap/domain'

    def initialize(options = {})
      @uid = options[:uid] || "sAMAccountName"

      @connection = Net::LDAP.new({
        host: options[:host],
        port: options[:port]
      })

      @connection.authenticate(options[:admin_user], options[:admin_password])

      if encryption = check_encryption(options[:encryptation])
        @connection.encryption(encryption)
      end
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
      @connection.bind
    end

    # Creates a new domain object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Domain object.
    def domain(base_name)
      Domain.new(base_name, @connection, @uid)
    end
  end
end
