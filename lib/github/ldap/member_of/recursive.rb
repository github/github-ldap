module GitHub
  class Ldap
    module MemberOf
      # Look up the groups an entry is a member of, including nested subgroups.
      #
      # NOTE: this strategy is network and performance intensive.
      class Recursive
        include Filter

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Internal: The maximum depth to search for subgroups.
        attr_reader :depth

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
          @depth   = options[:depth]
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

          entries = domains.each_with_object([]) do |domain, entries|
            entries.concat domain.search(filter: filter)
          end

          entries.each_with_object(entries.dup) do |entry, entries|
            entries.concat search_strategy.perform(entry)
          end.select { |entry| group?(entry) }
        end

        # Internal: Domains to search through.
        #
        # Returns an Array of GitHub::Ldap::Domain objects.
        def domains
          @domains ||= ldap.search_domains.map { |base| ldap.domain(base) }
        end
        private :domains

        # Internal: The search strategy to recursively search for nested
        # subgroups with.
        def search_strategy
          @search_strategy ||=
            GitHub::Ldap::Members::Recursive.new ldap,
              depth: depth,
              attrs: %w(objectClass)
        end

        # Internal: Returns true if the entry is a group.
        def group?(entry)
          GitHub::Ldap::Group.group?(entry[:objectclass])
        end
      end
    end
  end
end
