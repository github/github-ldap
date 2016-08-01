module GitHub
  class Ldap
    class ReferralChaser

      def initialize(connection)
        @connection = connection
        @admin_user = connection.admin_user
        @admin_password = connection.admin_password
      end

      def search(options)
        search_results = []
        referral_entries = []

        search_results = connection.search(options) do |referral_entry|
          referral_entries << referral_entry
        end

        unless referral_entries.empty?
          entry = referral_entries.first
          referral_string = entry[:search_referrals].first
          referral = Referral.new(referral_string, admin_user, admin_password, port)
          search_results = referral.search(options)
        end

        search_results
      end

      private

      attr_reader :connection, :admin_user, :admin_password, :port

      # Represents a referral entry from an LDAP search result. Constructs a corresponding
      # GitHub::Ldap object from the paramaters on the referral_url and provides a #search
      # method to continue the search on the referred domain.
      class Referral
        def initialize(referral_url, admin_user, admin_password, port=nil)
          url = GitHub::Ldap::URL.new(referral_url)
          @search_base = url.dn

          connection_options = {
            host: url.host,
            port: port || url.port,
            scope: url.scope,
            admin_user: admin_user,
            admin_password: admin_password
          }

          @connection = GitHub::Ldap::ConnectionCache.get_connection(connection_options)
        end

        # Search the referred domain controller with options, merging in the referred search
        # base DN onto options[:base].
        def search(options)
          connection.search(options.merge(base: search_base))
        end

        attr_reader :search_base, :connection
      end
    end
  end
end
