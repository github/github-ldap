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

      # Public - Get all members that belong to a group.
      # This list also includes the members of subgroups.
      #
      # Returns an array with all the member entries.
      def members
        groups, members = groups_and_members
        results = members

        cache = load_cache(groups)

        loop_cached_groups(groups, cache) do |_, users|
          results.concat users
        end

        results.uniq {|m| m.dn }
      end

      # Public - Get all the subgroups from a group recursively.
      #
      # Returns an array with all the subgroup entries.
      def subgroups
        groups, _ = groups_and_members
        results = groups

        cache = load_cache(groups)

        loop_cached_groups(groups, cache) do |subgroups, _|
          results.concat subgroups
        end

        results
      end

      # Public - Check if a user dn is included in the members of this group and its subgroups.
      #
      # user_dn: is the dn to check.
      #
      # Returns true if the dn is in the list of members.
      def is_member?(user_dn)
        members.detect {|entry| entry.dn == user_dn}
      end


      # Internal - Get all the member entries for a group.
      #
      # Returns an array of Net::LDAP::Entry.
      def member_entries
        @member_entries ||= member_names.each_with_object([]) do |m, a|
          entry = @ldap.domain(m).bind
          a << entry if entry
        end
      end

      # Internal - Get all the names under `member` and `uniqueMember`.
      #
      # Returns an array with all the DN members.
      def member_names
        @entry[:member] + @entry[:uniqueMember]
      end

      # Internal - Check if an object class includes the member names
      # Use `&` rathen than `include?` because both are arrays.
      #
      # Returns true if the object class includes one of the group class names.
      def group?(object_class)
        !(GROUP_CLASS_NAMES & object_class).empty?
      end

      # Internal - Generate a hash with all the group DNs for caching purposes.
      #
      # groups: is an array of group entries.
      #
      # Returns a hash with the cache groups.
      def load_cache(groups)
        groups.each_with_object({}) {|entry, h| h[entry.dn] = true }
      end

      # Internal - Iterate over a collection of groups recursively.
      # Remove groups already inspected before iterating over subgroups.
      #
      # groups: is an array of group entries.
      # cache: is a hash where the keys are group dns.
      # block: is a block to call with the groups and members of subgroups.
      #
      # Returns nothing.
      def loop_cached_groups(groups, cache, &block)
        groups.each do |result|
          subgroups, members = @ldap.group(result.dn).groups_and_members

          subgroups.delete_if {|entry| cache[entry.dn]}
          subgroups.each {|entry| cache[entry.dn] = true}

          block.call(subgroups, members)
          loop_cached_groups(subgroups, cache, &block)
        end
      end

      # Internal - Divide members of a group in user and subgroups.
      #
      # Returns two arrays, the first one with subgroups and the second one with users.
      def groups_and_members
        member_entries.partition {|e| group?(e[:objectclass])}
      end
    end
  end
end
