module GitHub
  class Ldap
    module MemberSearch
      # Look up group members using the existing `Group#members` and
      # `Group#subgroups` API.
      class Classic < Base
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
