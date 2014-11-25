module GitHub
  class Ldap
    module Members
      # Look up group members recursively.
      #
      # In this case, we're returning User Net::LDAP::Entry objects, not entries
      # for LDAP Groups.
      #
      # This results in a maximum of `depth` queries (per domain) to look up
      # members of a group and its subgroups.
      class Recursive
        include Filter

        DEFAULT_MAX_DEPTH = 9
        ATTRS             = %w(dn cn)

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
        end

        # Internal: Domains to search through.
        #
        # Returns an Array of GitHub::Ldap::Domain objects.
        def domains
          @domains ||= ldap.search_domains.map { |base| ldap.domain(base) }
        end
        private :domains

        # Public: Performs search for group members, including members of
        # subgroups recursively.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(group, depth = DEFAULT_MAX_DEPTH)
          members = Hash.new

          member_dns = group["member"]

          domains.each do |domain|
            # find members
            entries = domain.search(filter: membership_filter(member_dns), attributes: ATTRS)

            next if entries.empty?

            return entries
          end

          []
        end

        # Internal: Construct a filter to find groups this entry is a direct
        # member of.
        #
        # Overloads the included `GitHub::Ldap::Filters#member_filter` method
        # to inject `posixGroup` handling.
        #
        # Returns a Net::LDAP::Filter object.
        def member_filter(entry_or_uid, uid = ldap.uid)
          filter = super(entry_or_uid)

          if ldap.posix_support_enabled?
            if posix_filter = posix_member_filter(entry_or_uid, uid)
              filter |= posix_filter
            end
          end

          filter
        end

        # Internal: Construct a filter to find groups whose members are the
        # Array of String group DNs passed in.
        #
        # Returns a String filter.
        def membership_filter(groups)
          groups.map { |entry| member_filter(entry, :cn) }.reduce(:|)
        end

        # Internal: the group DNs to check against.
        #
        # Returns an Array of String DNs.
        def group_dns
          @group_dns ||= groups.map(&:dn)
        end
      end
    end
  end
end
