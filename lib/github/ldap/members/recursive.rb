module GitHub
  class Ldap
    module Members
      # Look up group members recursively.
      #
      # This results in a maximum of `depth` iterations/recursions to look up
      # members of a group and its subgroups.
      class Recursive
        include Filter

        DEFAULT_MAX_DEPTH = 9
        ATTRS             = %w(dn member)

        # Internal: The GitHub::Ldap object to search domains with.
        attr_reader :ldap

        # Internal: The maximum depth to search for members.
        attr_reader :depth

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        def initialize(ldap, options = {})
          @ldap    = ldap
          @options = options
          @depth   = options[:depth] || DEFAULT_MAX_DEPTH
        end

        # Public: Performs search for group members, including groups and
        # members of subgroups recursively.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(group)
          found = Hash.new

          members = group["member"]
          return [] if members.empty?

          # find members (N queries)
          entries = entries_by_dn(members)
          return [] if entries.empty?

          # track found entries
          entries.each do |entry|
            found[entry.dn] = entry
          end

          # descend to `depth` levels, at most
          depth.times do |n|
            # find every (new, unique) member entry
            depth_subentries = entries.each_with_object([]) do |entry, depth_entries|
              submembers = entry["member"]

              # skip any members we've already found
              submembers.reject! { |dn| found.key?(dn) }

              next if submembers.empty?

              # find members of subgroup, including subgroups (N queries)
              subentries = entries_by_dn(submembers)

              # track found subentries
              subentries.each { |entry| found[entry.dn] = entry }

              # collect all entries for this depth
              depth_entries.concat subentries
            end

            # stop if there are no more subgroups to search
            break if depth_subentries.empty?

            # go one level deeper
            entries = depth_subentries
          end

          # return all found entries
          found.values
        end

        # Internal: Bind a list of DNs to their respective entries.
        #
        # Returns an Array of Net::LDAP::Entry objects.
        def entries_by_dn(members)
          members.map do |dn|
            ldap.domain(dn).bind(attributes: ATTRS)
          end.compact
        end
      end
    end
  end
end
