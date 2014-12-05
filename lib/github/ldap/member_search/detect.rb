module GitHub
  class Ldap
    module MemberSearch
      # Detects the LDAP host's capabilities and determines the appropriate
      # member search strategy at runtime.
      #
      # Currently detects for ActiveDirectory in-chain membership validation.
      #
      # An explicit strategy can also be defined via
      # `GitHub::Ldap#member_search_strategy=`.
      #
      # See also `GitHub::Ldap#configure_member_search_strategy`.
      class Detect
        # Defines `active_directory_capability?` and necessary helpers.
        include GitHub::Ldap::Capabilities

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Internal: The Hash of options to pass through to the strategy.
        attr_reader :options

        # Public: Instantiate a meta strategy to detect the right strategy
        # to use for the search, and call that strategy, at runtime.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options (passed through)
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
        end

        # Public: Performs search for group members via the appropriate search
        # strategy detected/configured.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(entry)
          strategy.perform(entry)
        end

        # Internal: Returns the member search strategy object.
        def strategy
          @strategy ||= begin
            strategy = detect_strategy
            strategy.new(ldap, options)
          end
        end

        # Internal: Find the most appropriate search strategy, either by
        # configuration or by detecting the host's capabilities.
        #
        # Returns the strategy class.
        def detect_strategy
          case
          when GitHub::Ldap::MemberSearch::STRATEGIES.key?(strategy_config)
            GitHub::Ldap::MemberSearch::STRATEGIES[strategy_config]
          when active_directory_capability?
            GitHub::Ldap::MemberSearch::STRATEGIES[:active_directory]
          else
            GitHub::Ldap::MemberSearch::STRATEGIES[:recursive]
          end
        end

        # Internal: Returns the configured member search strategy Symbol.
        def strategy_config
          ldap.member_search_strategy
        end
      end
    end
  end
end
