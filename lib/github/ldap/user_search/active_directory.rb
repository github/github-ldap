module GitHub
  class Ldap
    module UserSearch
      class ActiveDirectory < Default

        # Public - Overridden from base class to set the base to "", and use the
        # Global Catalog to perform the user search.
        def search(search_options)
          # when doing a global search for a user's DN, set the search base to blank
          options[:base] = ""
          Array(global_catalog_connection.search(search_options.merge(options)))
        end

        # Returns a memoized connection to an Active Directory Global Catalog
        # if the server is an Active Directory instance, otherwise returns nil.
        #
        # See: https://technet.microsoft.com/en-us/library/cc728188(v=ws.10).aspx
        #
        def global_catalog_connection
          GlobalCatalog.connection(ldap)
        end
      end

      class GlobalCatalog < Net::LDAP
        STANDARD_GC_PORT = 3268
        LDAPS_GC_PORT = 3269

        def self.connection(ldap)
          @global_catalog_instance ||= begin
            netldap = ldap.connection
            # This is ugly, but Net::LDAP doesn't expose encryption or auth
            encryption = netldap.instance_variable_get(:@encryption)
            auth = netldap.instance_variable_get(:@auth)

            new({
              host: ldap.instance_variable_get(:@host),
              instrumentation_service: ldap.instrumentation_service,
              port: encryption ? LDAPS_GC_PORT : STANDARD_GC_PORT,
              auth: auth,
              encryption: encryption
            })
          end
        end
      end
    end
  end
end
