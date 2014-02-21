module GitHub
  class Ldap
    require 'net/ldap'
    require 'forwardable'
    require 'github/ldap/filter'
    require 'github/ldap/domain'
    require 'github/ldap/group'
    require 'github/ldap/virtual_group'

    extend Forwardable

    # Utility method to perform searches against the ldap server.
    #
    # It takes the same arguments than Net:::LDAP#search.
    # Returns an Array with the entries that match the search.
    # Returns nil if there are no entries that match the search.
    def_delegator :@connection, :search

    # Utility method to get the last operation result with a human friendly message.
    #
    # Returns an OpenStruct with `code` and `message`.
    # If `code` is 0, the operation succeeded and there is no message.
    def_delegator :@connection, :get_operation_result, :last_operation_result

    def initialize(options = {})
      @uid = options[:uid] || "sAMAccountName"

      @connection = Net::LDAP.new({host: options[:host], port: options[:port]})

      if options[:admin_user] && options[:admin_password]
        @connection.authenticate(options[:admin_user], options[:admin_password])
      end

      if encryption = check_encryption(options[:encryption])
        @connection.encryption(encryption)
      end

      @virtual_attributes = options[:virtual_attributes]
    end

    # Check whether the ldap server supports virual attributes or not.
    #
    # Returns true of we create the ldap object with that option.
    def virtual_attributes?
      @virtual_attributes
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
      last_operation_result
    end

    # Creates a new domain object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Domain object.
    def domain(base_name)
      Domain.new(base_name, @connection, @uid)
    end

    # Creates a new group object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Group object.
    def group(base_name)
      if virtual_attributes?
        VirtualGroup.new(self, domain(base_name).bind)
      else
        Group.new(self, domain(base_name).bind)
      end
    end
  end
end
