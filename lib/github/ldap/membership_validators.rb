require 'github/ldap/membership_validators/base'
require 'github/ldap/membership_validators/classic'
require 'github/ldap/membership_validators/recursive'

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
    module MembershipValidators; end
  end
end
