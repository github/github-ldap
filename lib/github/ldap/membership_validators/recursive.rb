module GitHub
  class Ldap
    module MembershipValidators
      # Validates membership recursively.
      #
      # The first step checks whether the entry is a direct member of the given
      # groups. If they are, then we've validated membership successfully.
      #
      # If not, query for all of the groups that have our groups as members,
      # then we check if the entry is a member of any of those.
      #
      # This is repeated until the entry is found, recursing and requesting
      # groups in bulk each iteration until we hit the maximum depth allowed
      # and have to give up.
      #
      # This results in a maximum of `depth` queries (per domain) to validate
      # membership in a list of groups.
      class Recursive < Base
        include Filter

        DEFAULT_MAX_DEPTH = 9
        ATTRS             = %w(dn cn)

        # Internal: The maximum depth to search for membership.
        attr_reader :depth

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - groups:  Array of Net::LDAP::Entry group objects
        # - options: Hash of options
        #   depth:   Integer limit of recursion
        #
        # NOTE: This overrides default behavior to configure `depth`.
        def initialize(ldap, groups, options = {})
          super
          @depth = options[:depth] || DEFAULT_MAX_DEPTH
        end

        def perform(entry, depth_override = nil)
          if depth_override
            warn "DEPRECATION WARNING: Calling Recursive#perform with a second argument is deprecated."
            warn "Usage:"
            warn "  strategy = GitHub::Ldap::MembershipValidators::Recursive.new \\"
            warn "    ldap, depth: 5"
            warn "  strategy#perform(entry)"
          end

          # short circuit validation if there are no groups to check against
          return true if groups.empty?

          domains.each do |domain|
            # find groups entry is an immediate member of
            membership = domain.search(filter: member_filter(entry), attributes: ATTRS)

            # success if any of these groups match the restricted auth groups
            return true if membership.any? { |entry| group_dns.include?(entry.dn) }

            # give up if the entry has no memberships to recurse
            next if membership.empty?

            # recurse to at most `depth`
            (depth_override || depth).times do |n|
              # find groups whose members include membership groups
              membership = domain.search(filter: membership_filter(membership), attributes: ATTRS)

              # success if any of these groups match the restricted auth groups
              return true if membership.any? { |entry| group_dns.include?(entry.dn) }

              # give up if there are no more membersips to recurse
              break if membership.empty?
            end

            # give up on this base if there are no memberships to test
            next if membership.empty?
          end

          false
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
