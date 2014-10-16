module GitHub
  class Ldap
    module MembershipValidators
      ATTRS = %w(dn)
      OID   = "1.2.840.113556.1.4.1941"

      # Validates membership using the ActiveDirectory "in chain" matching rule.
      #
      # The 1.2.840.113556.1.4.1941 matching rule (LDAP_MATCHING_RULE_IN_CHAIN)
      # "walks the chain of ancestry in objects all the way to the root until
      # it finds a match".
      # Source: http://msdn.microsoft.com/en-us/library/aa746475(v=vs.85).aspx
      #
      # This means we have an efficient method of searching membership even in
      # nested groups, performed on the server side.
      class ActiveDirectory < Base
        def perform(entry)
          # search for the entry on the condition that the entry is a member
          # of one of the groups or their subgroups.
          #
          # Sets the entry to the base and scopes the search to the base,
          # according to the source documentation, found here:
          # http://msdn.microsoft.com/en-us/library/aa746475(v=vs.85).aspx
          matched = ldap.search \
            filter: membership_in_chain_filter(entry),
            base:   entry.dn,
            scope:  Net::LDAP::SearchScope_BaseObject,
            attributes: ATTRS

          # membership validated if entry was matched and returned as a result
          matched.map(&:dn).include?(entry.dn)
        end

        # Internal: Constructs a membership filter using the "in chain"
        # extended matching rule afforded by ActiveDirectory.
        #
        # Returns a Net::LDAP::Filter object.
        def membership_in_chain_filter(entry)
          group_dns.map do |dn|
            Net::LDAP::Filter.ex("memberOf:#{OID}", dn)
          end.reduce(:|)
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
