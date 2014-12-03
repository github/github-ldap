module GitHub
  class Ldap
    module MembershipValidators
      # Validates membership recursively using virtual attributes.
      class VirtualAttributes < Base
        include Filter

        DEFAULT_MAX_DEPTH = 9
        ATTRS             = %w(dn cn memberOf)

        def perform(entry, depth = DEFAULT_MAX_DEPTH)
          return true if groups.empty?

          domains.each do |domain|
            # get groups entry is an immediate member of
            membership = entry[member_of_attr]

            # success if any of these groups match the restricted auth groups
            return true if membership.any? { |dn| group_dns.include?(dn) }

            # give up if the entry has no memberships to recurse
            next if membership.empty?

            # recurse to at most `depth`
            depth.times do |n|
              # find groups whose members include membership groups
              membership = domain.search(filter: membership_filter(membership), attributes: ATTRS).map(&:dn)

              # give up if the entry has no memberships to check
              next if membership.empty?

              # success if any of these groups match the restricted auth groups
              return true if membership.any? { |dn| group_dns.include?(dn) }

              # give up if there are no more membersips to recurse
              break if membership.empty?
            end

            # give up on this base if there are no memberships to test
            next if membership.empty?
          end

          false
        end

        # Internal: Returns the String memberOf virtual attribute name.
        def member_of_attr
          @member_of_attr ||= ldap.virtual_attributes.virtual_membership
        end

        # Internal: Construct a filter to find groups this entry is a direct
        # member of.
        #
        # Overloads the included `GitHub::Ldap::Filters#member_filter` method
        # to inject `posixGroup` handling.
        #
        # Returns a Net::LDAP::Filter object.
        def member_filter(dn)
          Net::LDAP::Filter.eq(member_of_attr, dn)
        end

        # Internal: Construct a filter to find groups whose members are the
        # Array of String group DNs passed in.
        #
        # Returns a String filter.
        def membership_filter(groups)
          groups.map { |dn| member_filter(dn) }.reduce(:|)
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
