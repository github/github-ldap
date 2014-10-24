module GitHub
  class Ldap
    module MembershipValidators
      # Detects the LDAP host's capabilities and determines the appropriate
      # membership validation strategy at runtime.
      class Detect < Base
        # Internal: The capability required to use the ActiveDirectory strategy.
        # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
        ACTIVE_DIRECTORY_V61_R2_OID = "1.2.840.113556.1.4.2080".freeze

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
        # If the strategy has been set explicitly, skips detection and uses the
        # configured strategy instead.
        #
        # Returns the strategy class.
        def detect_strategy
          case
          when GitHub::Ldap::MembershipValidators::STRATEGIES.key?(strategy_config)
            GitHub::Ldap::MembershipValidators::STRATEGIES[strategy_config]
          when active_directory_capability?
            GitHub::Ldap::MembershipValidators::STRATEGIES[:active_directory]
          else
            GitHub::Ldap::MembershipValidators::STRATEGIES[:recursive]
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
          capabilities[:supportcapabilities].include?(ACTIVE_DIRECTORY_V61_R2_OID)
        end

        # Internal: Searches the LDAP host's Root DSE for server capabilities.
        #
        # Returns the Net::LDAP::Entry object containing the Root DSE
        # results describing the server capabilities.
        def capabilities
          @ldap.instrument "capabilities.github_ldap_membership_validator" do |payload|
            @capabilities ||=
              begin
                ldap.search_root_dse
              rescue Net::LDAP::LdapError => error
                payload[:error] = error
                # stubbed result
                Net::LDAP::Entry.new
              end
          end
        end
      end
    end
  end
end
