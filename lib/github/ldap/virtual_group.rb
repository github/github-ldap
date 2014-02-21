module GitHub
  class Ldap
    class VirtualGroup < Group
      def members
        @ldap.search(filter: is_member_of_group(@entry.dn))
      end

      def subgroups
        @ldap.search(filter: is_subgroup_of_group(@entry.dn))
      end
    end
  end
end
