module GitHub
  class Ldap
    class VirtualAttributes
      def initialize(enabled, attributes = {})
        @enabled = enabled
        @attributes = attributes
      end

      def enabled?
        @enabled
      end

      def virtual_membership
        @attributes.fetch(:virtual_membership, "memberOf")
      end
    end
  end
end
