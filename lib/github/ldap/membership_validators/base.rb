module GitHub
  class Ldap
    module MembershipValidators
      class Base
        attr_reader :ldap, :groups

        # Public: Instantiate new validator.
        #
        # - ldap:   GitHub::Ldap object
        # - groups: Array of Net::LDAP::Entry group objects
        def initialize(ldap, groups)
          @ldap   = ldap
          @groups = groups
        end

        # Abstract: Performs the membership validation check.
        #
        # Returns Boolean whether the entry's membership is validated or not.
        # def perform(entry)
        # end

        # Internal: Domains to search through.
        #
        # Returns an Array of GitHub::Ldap::Domain objects.
        def domains
          @domains ||= ldap.search_domains.map { |base| ldap.domain(base) }
        end
      end
    end
  end
end
