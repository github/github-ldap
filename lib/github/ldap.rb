require 'net/ldap'
require 'forwardable'

require 'github/ldap/filter'
require 'github/ldap/domain'
require 'github/ldap/group'
require 'github/ldap/posix_group'
require 'github/ldap/virtual_group'
require 'github/ldap/virtual_attributes'
require 'github/ldap/instrumentation'
require 'github/ldap/member_search'
require 'github/ldap/membership_validators'

module GitHub
  class Ldap
    include Instrumentation

    extend Forwardable

    # Internal: The capability required to use ActiveDirectory features.
    # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
    ACTIVE_DIRECTORY_V51_OID = "1.2.840.113556.1.4.1670".freeze

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

    # Public - Opens a connection to the server and keeps it open for the
    # duration of the block.
    #
    # Returns the return value of the block.
    def_delegator :@connection, :open

    attr_reader :uid, :search_domains, :virtual_attributes,
                :membership_validator,
                :member_search_strategy,
                :instrumentation_service

    # Build a new GitHub::Ldap instance
    #
    # ## Connection
    #
    # host: required string ldap server host address
    # port: required string or number ldap server port
    # encryption: optional string. `ssl` or `tls`. nil by default
    # admin_user: optional string ldap administrator user dn for authentication
    # admin_password: optional string ldap administrator user password
    #
    # ## Behavior
    #
    # uid: optional field name used to authenticate users. Defaults to `sAMAccountName` (what ActiveDirectory uses)
    # virtual_attributes: optional. boolean true to use server's virtual attributes. Hash to specify custom mapping. Default false.
    # recursive_group_search_fallback: optional boolean whether membership checks should recurse into nested groups when virtual attributes aren't enabled. Default false.
    # posix_support: optional boolean `posixGroup` support. Default true.
    # search_domains: optional array of string bases to search through
    #
    # ## Diagnostics
    #
    # instrumentation_service: optional ActiveSupport::Notifications compatible object
    #
    def initialize(options = {})
      @uid = options[:uid] || "sAMAccountName"

      @connection = Net::LDAP.new({
        host: options[:host],
        port: options[:port],
        instrumentation_service: options[:instrumentation_service]
      })

      if options[:admin_user] && options[:admin_password]
        @connection.authenticate(options[:admin_user], options[:admin_password])
      end

      if encryption = check_encryption(options[:encryption])
        @connection.encryption(encryption)
      end

      configure_virtual_attributes(options[:virtual_attributes])

      # enable fallback recursive group search unless option is false
      @recursive_group_search_fallback = (options[:recursive_group_search_fallback] != false)

      # enable posixGroup support unless option is false
      @posix_support = (options[:posix_support] != false)

      # search_domains is a connection of bases to perform searches
      # when a base is not explicitly provided.
      @search_domains = Array(options[:search_domains])

      # configure both the membership validator and the member search strategies
      configure_search_strategy(options[:search_strategy])

      # enables instrumenting queries
      @instrumentation_service = options[:instrumentation_service]

      # active directory forest
      @forest = get_domain_forest(options[:search_forest])
    end

    # Public - Whether membership checks should recurse into nested groups when
    # virtual attributes aren't enabled. The fallback search has poor
    # performance characteristics in some cases, in which case this should be
    # disabled by passing :recursive_group_search_fallback => false.
    #
    # Returns true or false.
    def recursive_group_search_fallback?
      @recursive_group_search_fallback
    end

    # Public - Whether membership checks should include posixGroup filter
    # conditions on `memberUid`. Configurable since some LDAP servers don't
    # handle unsupported attribute queries gracefully.
    #
    # Enable by passing :posix_support => true.
    #
    # Returns true, false, or nil (assumed false).
    def posix_support_enabled?
      @posix_support
    end

    # Public - Utility method to check if the connection with the server can be stablished.
    # It tries to bind with the ldap auth default configuration.
    #
    # Returns an OpenStruct with `code` and `message`.
    # If `code` is 0, the operation succeeded and there is no message.
    def test_connection
      @connection.bind
      last_operation_result
    end

    # Public - Creates a new domain object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Domain object.
    def domain(base_name)
      Domain.new(self, base_name, @uid)
    end

    # Public - Creates a new group object to perform operations
    #
    # base_name: is the dn of the base root.
    #
    # Returns a new Group object.
    # Returns nil if the dn is not in the server.
    def group(base_name)
      entry = domain(base_name).bind
      return unless entry

      load_group(entry)
    end

    # Public - Create a new group object based on a Net::LDAP::Entry.
    #
    # group_entry: is a Net::LDAP::Entry.
    #
    # Returns a Group, PosixGroup or VirtualGroup object.
    def load_group(group_entry)
      if @virtual_attributes.enabled?
        VirtualGroup.new(self, group_entry)
      elsif posix_support_enabled? && PosixGroup.valid?(group_entry)
        PosixGroup.new(self, group_entry)
      else
        Group.new(self, group_entry)
      end
    end

    # Public - Search entries in the ldap server.
    #
    # options: is a hash with the same options that Net::LDAP::Connection#search supports.
    # block: is an optional block to pass to the search.
    #
    # Returns an Array of Net::LDAP::Entry.
    def search(options, &block)
      instrument "search.github_ldap", options.dup do |payload|
        result =
          if options[:base]
            forest_search(options, &block)
          else
            search_domains.each_with_object([]) do |base, result|
              rs = forest_search(options.merge(:base => base), &block)
              result.concat Array(rs) unless rs == false
            end
          end

        return [] if result == false
        Array(result)
      end
    end

    # Internal: Search within a ldap forest
    #
    # Returns an Array of Net::LDAP::Entry.
    def forest_search(options, &block)
      instrument "forest_search.github_ldap" do |payload|
        result =
          if @forest.empty?
            @connection.search(options, &block)
          else
            @forest.each_with_object([]) do |(rootdn, server), res|
              if options[:base].end_with?(rootdn)
                rs = server.search(options, &block)
                res.concat Array(rs) unless rs == false
              end
            end
          end
        return result
      end
    end

    # Internal: Searches the host LDAP server's Root DSE for capabilities and
    # extensions.
    #
    # Returns a Net::LDAP::Entry object.
    def capabilities
      @capabilities ||=
        instrument "capabilities.github_ldap" do |payload|
          begin
            rs = @connection.search(:ignore_server_caps => true, :base => "", :scope => Net::LDAP::SearchScope_BaseObject)
            (rs and rs.first)
          rescue Net::LDAP::LdapError => error
            payload[:error] = error
            # stubbed result
            Net::LDAP::Entry.new
          end
        end
    end

    # Internal - Determine whether to use encryption or not.
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

    # Internal - Configure virtual attributes for this server.
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

    # Internal: Configure the member search and membership validation strategies.
    #
    # TODO: Inline the logic in these two methods here.
    #
    # Returns nothing.
    def configure_search_strategy(strategy = nil)
      # configure which strategy should be used to validate user membership
      configure_membership_validation_strategy(strategy)

      # configure which strategy should be used for member search
      configure_member_search_strategy(strategy)
    end

    # Internal: Configure the membership validation strategy.
    #
    # If no known strategy is provided, detects ActiveDirectory capabilities or
    # falls back to the Recursive strategy by default.
    #
    # Returns the membership validator strategy Class.
    def configure_membership_validation_strategy(strategy = nil)
      @membership_validator =
        case strategy.to_s
        when "classic"
          GitHub::Ldap::MembershipValidators::Classic
        when "recursive"
          GitHub::Ldap::MembershipValidators::Recursive
        when "active_directory"
          GitHub::Ldap::MembershipValidators::ActiveDirectory
        else
          # fallback to detection, defaulting to recursive strategy
          if active_directory_capability?
            GitHub::Ldap::MembershipValidators::ActiveDirectory
          else
            GitHub::Ldap::MembershipValidators::Recursive
          end
        end
    end

    # Internal: Configure the member search strategy.
    #
    #
    # If no known strategy is provided, detects ActiveDirectory capabilities or
    # falls back to the Recursive strategy by default.
    #
    # Returns the selected strategy Class.
    def configure_member_search_strategy(strategy = nil)
      @member_search_strategy =
        case strategy.to_s
        when "classic"
          GitHub::Ldap::MemberSearch::Classic
        when "recursive"
          GitHub::Ldap::MemberSearch::Recursive
        when "active_directory"
          GitHub::Ldap::MemberSearch::ActiveDirectory
        else
          # fallback to detection, defaulting to recursive strategy
          if active_directory_capability?
            GitHub::Ldap::MemberSearch::ActiveDirectory
          else
            GitHub::Ldap::MemberSearch::Recursive
          end
        end
    end

    # Internal: Queries configuration for available domains
    #
    # Membership of local or global groups need to be evaluated by contacting referral Donmain Controllers
    #
    # Returns all Domain Controllers within the forest
    def get_domain_forest(search_forest)
      instrument "get_domain_forest.github_ldap" do |payload|

        # if we are talking to an active directory
        if search_forest and active_directory_capability? and capabilities[:configurationnamingcontext].any?
          domains = @connection.search(
            base: capabilities[:configurationnamingcontext].first,
            search_referrals: true,
            filter: Net::LDAP::Filter.eq("nETBIOSName", "*")
          )
          return domains.each_with_object({}) do |server, result|
            if server[:ncname].any? and server[:dnsroot].any?
              result[server[:ncname].first] = Net::LDAP.new({
                host: server[:dnsroot].first,
                port: @connection.instance_variable_get(:@encryption)? 636 : 389,
                auth: @connection.instance_variable_get(:@auth),
                encryption: @connection.instance_variable_get(:@encryption),
                instrumentation_service: @connection.instance_variable_get(:@instrumentation_service)
              })
            end
          end
        end
        return {}
      end
    end

    # Internal: Detect whether the LDAP host is an ActiveDirectory server.
    #
    # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
    #
    # Returns true if the host is an ActiveDirectory server, false otherwise.
    def active_directory_capability?
      capabilities[:supportedcapabilities].include?(ACTIVE_DIRECTORY_V51_OID)
    end
    private :active_directory_capability?
  end
end
