module GitHub
  class Ldap
    require 'net/ldap'
    require 'github/ldap/domain'

    attr_reader :connection

    def initialize(options = {})
      @uid = options[:uid] || "sAMAccountName"

      @connection = Net::LDAP.new({host: options[:host], port: options[:port]})

      @connection.authenticate(options[:admin_user], options[:admin_password])

      if encryption = check_encryption(options[:encryption])
        @connection.encryption(encryption)
      end
    end

    # Determine whether to use encryption or not.
    #
    # encryption: is the encryption method, either 'ssl', 'tls', 'simple_tls' or 'start_tls'.
    #
    # Returns the real encryption type.
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
    # Returns an OpenStruct with `code` and `message`.
    # If `code` is 0, the operation succeeded and there is no message.
    def test_connection
      @connection.bind
      get_last_operation_result
    end

    # Utility method to get the last operation result with a human friendly message.
    #
    # Returns an OpenStruct with `code` and `message`.
    # If `code` is 0, the operation succeeded and there is no message.
    def get_last_operation_result
      @connection.get_operation_result
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
