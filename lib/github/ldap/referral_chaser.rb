module GitHub
  class Ldap
    class ReferralChaser

      def initialize(referral_entries, admin_user, admin_password)
        @referral_entries = referral_entries
        @admin_user = admin_user
        @admin_password = admin_password
      end

      def with_referrals
        referral_entries.each do |entry|
          entry[:search_referrals].each do |referral_string|
            yield(Referral.new(referral_string, admin_user, admin_password))
          end
        end
      end

      private

      attr_reader :referral_entries, :admin_user, :admin_password

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
