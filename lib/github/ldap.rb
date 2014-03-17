module GitHub
  class Ldap
    require 'net/ldap'
    require 'forwardable'
    require 'github/ldap/filter'
    require 'github/ldap/domain'
    require 'github/ldap/group'
    require 'github/ldap/virtual_group'
    require 'github/ldap/virtual_attributes'

    extend Forwardable

    # Utility method to get the last operation result with a human friendly message.
    #
    # Returns an OpenStruct with `code` and `message`.
    # If `code` is 0, the operation succeeded and there is no message.
    def_delegator :@connection, :get_operation_result, :last_operation_result

    # Utility method to bind entries in the ldap server.
    #
    # It takes the same arguments than Net::LDAP::Connection#bind.
    # Returns a Net::LDAP::Entry if the operation succeeded.
    def_delegator :@connection, :bind

    attr_reader :uid, :virtual_attributes, :search_domains

    def initialize(options = {})
      @uid = options[:uid] || "sAMAccountName"

      @connection = Net::LDAP.new({host: options[:host], port: options[:port]})

      if options[:admin_user] && options[:admin_password]
        @connection.authenticate(options[:admin_user], options[:admin_password])
      end

      if encryption = check_encryption(options[:encryption])
        @connection.encryption(encryption)
      end

      configure_virtual_attributes(options[:virtual_attributes])

      # search_domains is a connection of bases to perform searches
      # when a base is not explicitly provided.
      @search_domains = Array(options[:search_domains])
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
      Domain.new(self, base_name, @uid)
    end

    # Creates a new group object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Group object.
    # Returns nil if the dn is not in the server.
    def group(base_name)
      entry = domain(base_name).bind
      return unless entry

      if @virtual_attributes.enabled?
        VirtualGroup.new(self, entry)
      else
        Group.new(self, entry)
      end
    end

    # Configure virtual attributes for this server.
    # If the option is `true`, we'll use the default virual attributes.
    # If it's a Hash we'll map the attributes in the hash.
    #
    # attributes: is the option set when Ldap is initialized.
    #
    # Returns a VirtualAttributes.
    def configure_virtual_attributes(attributes)
      @virtual_attributes = if attributes == true
        VirtualAttributes.new(true)
      elsif attributes.is_a?(Hash)
        VirtualAttributes.new(true, attributes)
      else
        VirtualAttributes.new(false)
      end
    end

    def search(options)
      if options.key?(:base)
        @connection.search(options)
      else
        search_domains.each_with_object([]) do |base, result|
          rs = @connection.search(options.merge(:base => base))
          result.concat Array(rs) unless rs == false
        end
      end
    end
  end
end
