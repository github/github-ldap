require 'github/ldap/members/classic'
require 'github/ldap/members/recursive'

module GitHub
  class Ldap
    # Provides various strategies for member lookup.
    #
    # For example:
    #
    #   group = domain.groups(%w(Engineering)).first
    #   strategy = GitHub::Ldap::Members::Recursive.new(ldap)
    #   strategy.perform(group) #=> [#<Net::LDAP::Entry>]
    #
    module Members
      # Internal: Mapping of strategy name to class.
      STRATEGIES = {
        :classic   => GitHub::Ldap::Members::Classic,
        :recursive => GitHub::Ldap::Members::Recursive
      }
    end
  end
end
