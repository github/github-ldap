module GitHub
  class Ldap
    module Members
      # Look up group members using the existing `Group#members` and
      # `Group#subgroups` API.
      class Classic
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

        # Public: Performs search for group members, including groups and
        # members of subgroups recursively.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(group_entry)
          group = ldap.load_group(group_entry)
          group.members + group.subgroups
        end
      end
    end
  end
end
