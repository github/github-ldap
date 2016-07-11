require 'github/ldap/instrumentation'

module GitHub
  class Ldap
    # For ActiveDirectory environments that have a forest with multiple domain controllers,
    # this strategy class allows for entry searches across all domains in that forest.
    class ForestSearch
      include Instrumentation

      # Build a new GitHub::Ldap::ForestSearch instance
      #
      # connection:     GitHub::Ldap object representing the main AD connection.
      # naming_context: The Distinguished Name (DN) of this forest's Configuration
      #                 Naming Context, e.g., "CN=Configuration,DC=ad,DC=ghe,DC=com"
      #
      # See: https://technet.microsoft.com/en-us/library/aa998375(v=exchg.65).aspx
      #
      def initialize(connection, naming_context)
        @naming_context = naming_context
        @connection = connection
      end

      # Search over all domain controllers in the ActiveDirectory forest.
      #
      # options: options hash passed in from GitHub::Ldap#search
      # &block:  optional block passed in from GitHub::Ldap#search
      #
      # If no domain controllers are found in the forest, fall back on searching
      # the main GitHub::Ldap object in @connection.
      #
      # If @forest is populated, iterate over each domain controller and perform
      # the requested search, excluding domain controllers whose naming context
      # is not in scope for the search base DN defined in options[:base].
      #
      def search(options, &block)
        instrument "forest_search.github_ldap" do
          if forest.empty?
            @connection.search(options, &block)
          else
            forest.each_with_object([]) do |(ncname, connection), res|
              if options[:base].end_with?(ncname)
                rs = connection.search(options, &block)
                res.concat Array(rs) unless rs == false
              end
            end
          end
        end
      end

      private

      attr_reader :connection, :naming_context

      # Internal: Queries configuration for available domains
      #
      # Membership of local or global groups need to be evaluated by contacting referral Donmain Controllers
      #
      # Returns all Domain Controllers within the forest
      def get_domain_forest
        instrument "get_domain_forest.github_ldap" do |payload|
          domains = @connection.search(
            base: naming_context,
            search_referrals: true,
            filter: Net::LDAP::Filter.eq("nETBIOSName", "*")
          )
          unless domains.nil?
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

    end
  end
end
