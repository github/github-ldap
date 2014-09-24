module GitHub
  module Ldap
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
          ldap.search_domains
        end
      end
    end
  end
end
