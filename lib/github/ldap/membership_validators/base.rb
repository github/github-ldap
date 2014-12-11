module GitHub
  class Ldap
    module MembershipValidators
      class Base

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Internal: an Array of Net::LDAP::Entry group objects to validate with.
        attr_reader :groups

        # Public: Instantiate new validator.
        #
        # - ldap:   GitHub::Ldap object
        # - groups: Array of Net::LDAP::Entry group objects
        # - options: Hash of options
        def initialize(ldap, groups, options = {})
          @ldap    = ldap
          @groups  = groups
          @options = options
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
        private :domains
      end
    end
  end
end
