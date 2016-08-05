module GitHub
  class Ldap

    # This class adds referral chasing capability to a GitHub::Ldap connection.
    #
    # See: https://technet.microsoft.com/en-us/library/cc978014.aspx
    #      http://www.umich.edu/~dirsvcs/ldap/doc/other/ldap-ref.html
    #
    class ReferralChaser

      # Public - Creates a ReferralChaser that decorates an instance of GitHub::Ldap
      # with additional functionality to the #search method, allowing it to chase
      # any referral entries and aggregate the results into a single response.
      #
      # connection - The instance of GitHub::Ldap to use for searching. Will use
      # the connection's authentication, (admin_user and admin_password) as credentials
      # for connecting to referred domain controllers.
      def initialize(connection)
        @connection = connection
        @admin_user = connection.admin_user
        @admin_password = connection.admin_password
        @port = connection.port
      end

      # Public - Search the domain controller represented by this instance's connection.
      # If a referral is returned, search only one of the domain controllers indicated
      # by the referral entries, per RFC 4511 (https://tools.ietf.org/html/rfc4511):
      #
      # "If the client wishes to progress the operation, it contacts one of
      #  the supported services found in the referral.  If multiple URIs are
      #  present, the client assumes that any supported URI may be used to
      #  progress the operation."
      #
      # options - is a hash with the same options that Net::LDAP::Connection#search supports.
      #           Referral searches will use the given options, but will replace options[:base]
      #           with the referral URL's base search dn.
      #
      # Does not take a block argument as GitHub::Ldap and Net::LDAP::Connection#search do.
      #
      # Will not recursively follow any subsequent referrals.
      #
      # Returns an Array of Net::LDAP::Entry.
      def search(options)
        search_results = []
        referral_entries = []

        search_results = connection.search(options) do |entry|
          if entry && entry[:search_referrals]
            referral_entries << entry
          end
        end

        unless referral_entries.empty?
          entry = referral_entries.first
          referral_string = entry[:search_referrals].first
          if GitHub::Ldap::URL.valid?(referral_string)
            referral = Referral.new(referral_string, admin_user, admin_password, port)
            search_results = referral.search(options)
          end
        end

        Array(search_results)
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
