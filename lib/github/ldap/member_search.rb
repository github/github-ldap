require 'github/ldap/member_search/detect'
require 'github/ldap/member_search/classic'
require 'github/ldap/member_search/recursive'
require 'github/ldap/member_search/active_directory'

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
        :classic          => GitHub::Ldap::MemberSearch::Classic,
        :recursive        => GitHub::Ldap::MemberSearch::Recursive,
        :active_directory => GitHub::Ldap::MemberSearch::ActiveDirectory
      }
    end
  end
end
