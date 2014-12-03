require 'github/ldap/member_search/detect'
require 'github/ldap/member_search/classic'
require 'github/ldap/member_search/recursive'

module GitHub
  class Ldap
    # Provides various strategies for member lookup.
    #
    # For example:
    #
    #   group = domain.groups(%w(Engineering)).first
    #   strategy = GitHub::Ldap::MemberSearch::Recursive.new(ldap)
    #   strategy.perform(group) #=> [#<Net::LDAP::Entry>]
    #
    module MemberSearch
      # Internal: Mapping of strategy name to class.
      STRATEGIES = {
        :classic   => GitHub::Ldap::MemberSearch::Classic,
        :recursive => GitHub::Ldap::MemberSearch::Recursive
      }
    end
  end
end
