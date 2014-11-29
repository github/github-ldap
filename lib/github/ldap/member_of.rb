require 'github/ldap/member_of/classic'
require 'github/ldap/member_of/recursive'

module GitHub
  class Ldap
    # Provides various strategies to search for groups a user is a member of.
    #
    # For example:
    #
    #   group = domain.groups(%w(Engineering)).first
    #   strategy = GitHub::Ldap::MemberOf::Recursive.new(ldap)
    #   strategy.perform(user) #=> [#<Net::LDAP::Entry>]
    #
    module MemberOf
      # Internal: Mapping of strategy name to class.
      STRATEGIES = {
        :classic   => GitHub::Ldap::MemberOf::Classic,
        :recursive => GitHub::Ldap::MemberOf::Recursive
      }
    end
  end
end
