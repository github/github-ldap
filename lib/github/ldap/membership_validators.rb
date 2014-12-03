require 'github/ldap/membership_validators/base'
require 'github/ldap/membership_validators/detect'
require 'github/ldap/membership_validators/classic'
require 'github/ldap/membership_validators/recursive'
require 'github/ldap/membership_validators/active_directory'
require 'github/ldap/membership_validators/virtual_attributes'

module GitHub
  class Ldap
    # Provides various strategies for validating membership.
    #
    # For example:
    #
    #   groups = domain.groups(%w(Engineering))
    #   validator = GitHub::Ldap::MembershipValidators::Classic.new(ldap, groups)
    #   validator.perform(entry) #=> true
    #
    module MembershipValidators
      # Internal: Mapping of strategy name to class.
      STRATEGIES = {
        :classic          => GitHub::Ldap::MembershipValidators::Classic,
        :recursive        => GitHub::Ldap::MembershipValidators::Recursive,
        :active_directory => GitHub::Ldap::MembershipValidators::ActiveDirectory
      }
    end
  end
end
