module GitHub
  class Ldap
    # This class represents an LDAP group.
    # It encapsulates operations that you can perform against a group, like retrieving its members.
    #
    # To get a group, you'll need to create a `Ldap` object and then call the method `group` with the name of its base.
    #
    # For example:
    #
    # domain = GitHub::Ldap.new(options).group("cn=enterprise,dc=github,dc=com")
    #
    class Group
      GROUP_CLASS_NAMES = %w(groupOfNames groupOfUniqueNames)

      def initialize(ldap, entry)
        @ldap, @entry = ldap, entry
      end

      # Get all members that belong to a group.
      # This list also includes the members of subgroups.
      #
      # Returns an array with all the member entries.
      def members
        groups, members = member_entries.partition {|e| group?(e[:objectclass])}
        results = members

        groups.each do |result|
          results.concat @ldap.group(result.dn).members
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
          results.concat @ldap.group(result.dn).subgroups
        end

        results
      end

      # Get all the member entries for a group.
      #
      # Returns an array of Net::LDAP::Entry.
      def member_entries
        @member_entries ||= member_names.map do |m|
          @ldap.domain(m).bind
        end
      end

      # Get all the names under `member` and `uniqueMember`.
      #
      # Returns an array with all the DN members.
      def member_names
        @entry[:member] + @entry[:uniqueMember]
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
