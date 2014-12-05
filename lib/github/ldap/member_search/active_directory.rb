module GitHub
  class Ldap
    module MemberSearch
      # Look up group members using the ActiveDirectory "in chain" matching rule.
      #
      # The 1.2.840.113556.1.4.1941 matching rule (LDAP_MATCHING_RULE_IN_CHAIN)
      # "walks the chain of ancestry in objects all the way to the root until
      # it finds a match".
      # Source: http://msdn.microsoft.com/en-us/library/aa746475(v=vs.85).aspx
      #
      # This means we have an efficient method of searching for group members,
      # even in nested groups, performed on the server side.
      class ActiveDirectory < Base
        OID = "1.2.840.113556.1.4.1941"

        # Internal: The default attributes to query for.
        # NOTE: We technically don't need any by default, but if we left this
        # empty, we'd be querying for *all* attributes which is less ideal.
        DEFAULT_ATTRS = %w(objectClass)

        # Internal: The attributes to search for.
        attr_reader :attrs

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        #
        # NOTE: This overrides default behavior to configure attrs`.
        def initialize(ldap, options = {})
          super
          @attrs = Array(options[:attrs]).concat DEFAULT_ATTRS
        end

        # Public: Performs search for group members, including groups and
        # members of subgroups, using ActiveDirectory's "in chain" matching
        # rule.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(group)
          filter = member_of_in_chain_filter(group)

          # search for all members of the group, including subgroups, by
          # searching "in chain".
          domains.each_with_object([]) do |domain, members|
            members.concat domain.search(filter: filter, attributes: attrs)
          end
        end

        # Internal: Constructs a member filter using the "in chain"
        # extended matching rule afforded by ActiveDirectory.
        #
        # Returns a Net::LDAP::Filter object.
        def member_of_in_chain_filter(entry)
          Net::LDAP::Filter.ex("memberOf:#{OID}", entry.dn)
        end
      end
    end
  end
end
