module GitHub
  class Ldap
    module MemberSearch
      class Base

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
        end

        # Public: Abstract: Performs search for group members.
        #
        # Returns Array of Net::LDAP::Entry objects.
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
