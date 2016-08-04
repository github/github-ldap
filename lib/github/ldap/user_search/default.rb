module GitHub
  class Ldap
    module UserSearch
      # The default user search strategy, mainly for allowing Domain#user? to
      # search for a user on the configured domain controller, or use the Global
      # Catalog to search across the entire Active Directory forest.
      class Default
        include Filter

        def initialize(ldap)
          @ldap = ldap
          @options = {
            :attributes => [],
            :paged_searches_supported => true,
            :size => 1
          }
        end

        # Performs a normal search on the configured domain controller
        # using the default base DN, uid, search_options
        def perform(login, base_name, uid, search_options)
          search_options[:filter] = login_filter(uid, login)
          search_options[:base] = base_name
          search(options.merge(search_options))
        end

        # The default search. This can be overridden by a child class
        # like GitHub::Ldap::UserSearch::ActiveDirectory to change the
        # scope of the search.
        def search(options)
          ldap.search(options)
        end

        private

        attr_reader :options, :ldap
      end
    end
  end
end
