module GitHub
  class Ldap
    module MembershipValidators
      # Validates membership using the `Domain#membership` lookup method.
      #
      # This is a simple wrapper for existing functionality in order to expose
      # it consistently with the new approach.
      class Classic < Base
        def perform(entry)
          return true if groups.empty?

          domains.each do |base_name, domain|
            membership = domain.membership(entry, groups)

            if !membership.empty?
              entry[:groups] = membership
              return true
            end
          end

          false
        end
      end
    end
  end
end
