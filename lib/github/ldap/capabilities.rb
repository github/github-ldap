module GitHub
  class Ldap
    module Capabilities
      # Internal: The capability required to use the ActiveDirectory strategy.
      # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
      ACTIVE_DIRECTORY_V61_R2_OID = "1.2.840.113556.1.4.2080".freeze

      # Internal: Detect whether the LDAP host is an ActiveDirectory server.
      #
      # See: http://msdn.microsoft.com/en-us/library/cc223359.aspx.
      #
      # Returns true if the host is an ActiveDirectory server, false otherwise.
      def active_directory_capability?
        capabilities[:supportedcapabilities].include?(ACTIVE_DIRECTORY_V61_R2_OID)
      end

      # Internal: Returns the Net::LDAP::Entry object describing the LDAP
      # host's capabilities (via the Root DSE).
      def capabilities
        ldap.capabilities
      end
    end
  end
end
