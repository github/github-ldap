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

        referral_entries.each do |entry|
          entry[:search_referrals].each do |referral_string|
            referral = Referral.new(referral_string, admin_user, admin_password)
            search_results.concat(referral.search(options))
          end
        end

        search_results
      end

      private

      attr_reader :connection, :admin_user, :admin_password

      class Referral
        def initialize(referral_string, admin_user, admin_password)
          uri = URI(referral_string)
          @search_base = URI.unescape(uri.path.sub(/^\//, ''))

          connection_options = {
            host: uri.host,
            admin_user: admin_user,
            admin_password: admin_password
          }

          @connection = GitHub::Ldap::ConnectionPool.get_connection(connection_options)
        end

        attr_reader :search_base, :connection
      end
    end
  end
end
