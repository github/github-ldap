module GitHub
  class Ldap
    class VirtualGroup < Group
      def members
        @ldap.search(filter: is_member_of_group(@entry.dn, membership_attribute))
      end

      def subgroups
        @ldap.search(filter: is_subgroup_of_group(@entry.dn, membership_attribute))
      end

      # Internal - Get the attribute to use for membership filtering.
      #
      # Returns a string.
      def membership_attribute
        @ldap.virual_attributes.virtual_membership
      end
    end
  end
end
