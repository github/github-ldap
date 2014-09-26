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
      autoload :Base,      'github/ldap/membership_validators/base'
      autoload :Classic,   'github/ldap/membership_validators/classic'
      autoload :Recursive, 'github/ldap/membership_validators/recursive'
    end
  end
end
