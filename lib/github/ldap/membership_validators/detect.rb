module GitHub
  class Ldap
    module MembershipValidators
      # Detects the LDAP host's capabilities and determines the appropriate
      # membership validation strategy at runtime.
      class Detect < Base
        # Internal: Mapping of strategy name to class.
        STRATEGIES = {
          :classic          => GitHub::Ldap::MembershipValidators::Classic,
          :recursive        => GitHub::Ldap::MembershipValidators::Recursive,
          :active_directory => GitHub::Ldap::MembershipValidators::ActiveDirectory
        }

        # Internal: The capability required to use the ActiveDirectory strategy.
        # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
        ACTIVE_DIRECTORY_V51_OID = "1.2.840.113556.1.4.1670".freeze

        def perform(entry)
          # short circuit validation if there are no groups to check against
          return true if groups.empty?

          strategy.perform(entry)
        end

        # Internal: Returns the membership validation strategy object.
        def strategy
          @strategy ||= begin
            strategy = detect_strategy
            strategy.new(ldap, groups)
          end
        end

        # Internal: Detects LDAP host's capabilities and chooses the best
        # strategy for the host.
        #
        # If the strategy has been
        #
        # Returns the strategy class.
        def detect_strategy
          return STRATEGIES[strategy_config] if STRATEGIES.key?(strategy_config)

          if active_directory_capability?
            :active_directory
          else
            :recursive
          end
        end

        # Internal: Returns the configured membership validator strategy Symbol.
        def strategy_config
          ldap.membership_validator
        end

        # Internal: Detect it the LDAP host is an ActiveDirectory server.
        #
        # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
        #
        # Returns true if the host is an ActiveDirectory server, false otherwise.
        def active_directory_capability?
          capabilities[:supportcapabilities].include?(ACTIVE_DIRECTORY_V51_OID)
        end

        # Internal: Searches the LDAP host's Root DSE for server capabilities.
        #
        # Returns the Net::LDAP::Entry object containing the Root DSE
        # results describing the server capabilities.
        def capabilities
          @capabilities ||= ldap.search_root_dse
        end
      end
    end
  end
end
