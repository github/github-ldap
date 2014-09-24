module GitHub
  class Ldap
    module MembershipValidators
      class Base
        attr_reader :ldap, :groups

        def initialize(ldap, groups)
          @ldap   = ldap
          @groups = groups
        end

        # Abstract: Performs the membership validation check.
        #
        # Returns Boolean whether the entry's membership is validated or not.
        # def perform(entry)
        # end

        def domains
          @domains ||= ldap.search_domains.map { |base| ldap.domain(base) }
        end
      end
    end
  end
end
