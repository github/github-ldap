module GitHub
  class Ldap
    class VirtualGroup < Group
      include Filter

      def members
        @ldap.search(filter: members_of_group(@entry.dn, membership_attribute))
      end

      def subgroups
        @ldap.search(filter: subgroups_of_group(@entry.dn, membership_attribute))
      end

      def is_member(user_dn)
        @ldap.search(filter: is_member_of_group(user_dn, @entry.dn, membership_attribute))
      end

      # Internal - Get the attribute to use for membership filtering.
      #
      # Returns a string.
      def membership_attribute
        @ldap.virtual_attributes.virtual_membership
      end
    end
  end
end
