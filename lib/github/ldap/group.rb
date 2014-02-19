module GitHub
  class Ldap
    # A group is a specialized version of a domain.
    # It encapsulates operations that you can perform against a group, like retrieving its members.
    #
    # To get a group, you'll need to create a `Ldap` object and then call the method `group` with the name of the base.
    #
    # For example:
    #
    # domain = GitHub::Ldap.new(options).group("cn=enterprise,dc=github,dc=com")
    #
    class Group < Domain
      GROUP_CLASS_NAMES = %w(groupOfNames groupOfUniqueNames)

      # Get all members that belong to a group.
      # This list also includes the members of subgroups.
      #
      # Returns an array with all the member entries.
      def members
        groups, members = member_entries.partition {|e| group?(e[:objectclass])}
        results = members

        groups.each do |result|
          results += Group.new(result.dn, @connection, @uid).members
        end

        results.uniq {|m| m.dn }
      end

      # Get all the subgroups from a group recursively.
      #
      # Returns an array with all the subgroup entries.
      def subgroups
        groups, _ = member_entries.partition {|e| group?(e[:objectclass])}
        results = groups

        groups.each do |result|
          results += Group.new(result.dn, @connection, @uid).subgroups
        end

        results
      end

      # Get all the member entries for a group.
      #
      # Returns an array of Net::LDAP::Entry.
      def member_entries
        rs = search({}).first

        members = rs[:member] + rs[:uniqueMember]
        members.map do |m|
          Domain.new(m, @connection, @uid).search({}).first
        end
      end

      # Check if an object class includes the member names
      # Use `&` rathen than `include?` because both are arrays.
      #
      # Returns true if the object class includes one of the group class names.
      def group?(object_class)
        !(GROUP_CLASS_NAMES & object_class).empty?
      end
    end
  end
end
