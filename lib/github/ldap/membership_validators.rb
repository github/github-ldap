module GitHub
  class Ldap
    # x
    #
    # For example:
    #
    #   validator = GitHub::Ldap::MembershipValidators::Classic.new(ldap, %w(Engineering))
    #   validator.perform(entry) #=> true
    #
    module MembershipValidators
      require 'github/ldap/membership_validators/base'

      autoload :Classic,   'github/ldap/membership_validators/classic'
      autoload :Recursive, 'github/ldap/membership_validators/recursive'
    end
  end
end
