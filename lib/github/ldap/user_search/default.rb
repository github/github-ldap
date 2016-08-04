module GitHub
  class Ldap
    module UserSearch
      class Default
        include Filter

        def initialize(ldap)
          @ldap = ldap
          @options = {}
          @options[:attributes] = []
          @options[:paged_searches_supported] = true
          @options[:size] = 1
        end

        def perform(login, base_name, uid, search_options)
          search_options[:filter] = login_filter(uid, login)
          search_options[:base] = base_name
          search(search_options.merge(options))
        end

        def search(options)
          ldap.search(options)
        end

        private

        attr_reader :options, :ldap
      end
    end
  end
end
