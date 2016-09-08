module GitHub
  class Ldap
    module UserSearch
      class ActiveDirectory < Default

        private

        # Private - Overridden from base class to set the base to "", and use the
        # Global Catalog to perform the user search.
        def search(search_options)
          Array(global_catalog_connection.search(search_options.merge(options)))
        end

        def global_catalog_connection
          GlobalCatalog.connection(ldap)
        end

        # When doing a global search for a user's DN, set the search base to blank
        def options
          super.merge(base: "")
        end
      end

      class GlobalCatalog < Net::LDAP
        STANDARD_GC_PORT = 3268
        LDAPS_GC_PORT = 3269

        # Returns a connection to the Active Directory Global Catalog
        #
        # See: https://technet.microsoft.com/en-us/library/cc728188(v=ws.10).aspx
        #
        def self.connection(ldap)
          @global_catalog_instance ||= begin
            netldap = ldap.connection
            # This is ugly, but Net::LDAP doesn't expose encryption or auth
            encryption = netldap.instance_variable_get(:@encryption)
            auth = netldap.instance_variable_get(:@auth)

            new({
              host: ldap.host,
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
