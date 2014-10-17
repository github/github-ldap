module GitHub
  class Ldap
    module MembershipValidators
      # Validates membership using `GitHub::Ldap::Domain#membership`.
      #
      # This is a simple wrapper for existing functionality in order to expose
      # it consistently with the new approach.
      class Classic < Base
        def perform(entry)
          # short circuit validation if there are no groups to check against
          return true if groups.empty?

          domains.each do |domain|
            membership = domain.membership(entry, group_names)

            if !membership.empty?
              entry[:groups] = membership
              return true
            end
          end

          false
        end

        # Internal: the group names to look up membership for.
        #
        # Returns an Array of String group names (CNs).
        def group_names
          @group_names ||= groups.map { |g| g[:cn].first }
        end
      end
    end
  end
end
