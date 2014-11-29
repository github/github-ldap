module GitHub
  class Ldap
    module MemberOf
      # Look up the groups an entry is a member of.
      class Classic
        include Filter

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options (unused)
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
        end

        # Public: Performs search for groups an entry is a member of, including
        # subgroups.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(entry)
          filter = member_filter(entry)

          if ldap.posix_support_enabled? && !entry[ldap.uid].empty?
            filter |= posix_member_filter(entry, ldap.uid)
          end

          domains.each_with_object([]) do |domain, entries|
            entries.concat domain.search(filter: filter)
          end
        end

        # Internal: Domains to search through.
        #
        # Returns an Array of GitHub::Ldap::Domain objects.
        def domains
          @domains ||= ldap.search_domains.map { |base| ldap.domain(base) }
        end
        private :domains
      end
    end
  end
end
