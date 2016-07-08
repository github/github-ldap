module GitHub
  class Ldap
    class ForestSearch

      def initialize(connection)
        @connection = connection
        @forest = get_domain_forest
      end

      def search(options, &block)
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

      private

      attr_reader :connection

      # Internal: Queries configuration for available domains
      #
      # Membership of local or global groups need to be evaluated by contacting referral Donmain Controllers
      #
      # Returns all Domain Controllers within the forest
      def get_domain_forest
        instrument "get_domain_forest.github_ldap" do |payload|
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
      end

    end
  end
end
