module GitHub
  class Ldap
    module UserSearch
      class ActiveDirectory < Default

        def initialize(ldap)
          @ldap = ldap
        end

        def search(options)
          # when doing a global search for a user's DN, set the search base to blank
          options[:base] = ""
          global_catalog_search(options).first
        end

        def global_catalog_search(options, &block)
          Array(global_catalog_connection.search(options, &block))
        end

        # Returns a memoized connection to an Active Directory Global Catalog
        # if the server is an Active Directory instance, otherwise returns nil.
        #
        # See: https://technet.microsoft.com/en-us/library/cc728188(v=ws.10).aspx
        #
        def global_catalog_connection
          @global_catalog_connection ||= Net::LDAP.new({
            host: ldap.instance_variable_get(:@host),
            auth: {
              method: :simple,
              username: ldap.instance_variable_get(:@admin_user),
              password: ldap.instance_variable_get(:@admin_password)
            },
            instrumentation_service: ldap.instrumentation_service,
            port: 3268,
          })
        end

        private

        attr_reader :ldap
      end
    end
  end
end
