module GitHub
  class Ldap
    module MemberSearch
      # Look up group members recursively.
      #
      # This results in a maximum of `depth` iterations/recursions to look up
      # members of a group and its subgroups.
      class Recursive < Base
        include Filter

        DEFAULT_MAX_DEPTH = 9
        DEFAULT_ATTRS     = %w(member uniqueMember memberUid)

        # Internal: The maximum depth to search for members.
        attr_reader :depth

        # Internal: The attributes to search for.
        attr_reader :attrs

        # Public: Instantiate new search strategy.
        #
        # - ldap:    GitHub::Ldap object
        # - options: Hash of options
        #
        # NOTE: This overrides default behavior to configure `depth` and `attrs`.
        def initialize(ldap, options = {})
          super
          @depth = options[:depth] || DEFAULT_MAX_DEPTH
          @attrs = Array(options[:attrs]).concat DEFAULT_ATTRS
        end

        # Public: Performs search for group members, including groups and
        # members of subgroups recursively.
        #
        # Returns Array of Net::LDAP::Entry objects.
        def perform(group)
          found = Hash.new

          # find members (N queries)
          entries = member_entries(group)
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

              # find members of subgroup, including subgroups (N queries)
              subentries = member_entries(entry)
              next if subentries.empty?

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

        # Internal: Fetch member entries, including subgroups, for the given
        # entry.
        #
        # Returns an Array of Net::LDAP::Entry objects.
        def member_entries(entry)
          entries = []
          dns     = member_dns(entry)
          uids    = member_uids(entry)

          entries.concat entries_by_uid(uids) unless uids.empty?
          entries.concat entries_by_dn(dns)   unless dns.empty?

          entries
        end
        private :member_entries

        # Internal: Bind a list of DNs to their respective entries.
        #
        # Returns an Array of Net::LDAP::Entry objects.
        def entries_by_dn(members)
          members.map do |dn|
            ldap.domain(dn).bind(attributes: attrs)
          end.compact
        end
        private :entries_by_dn

        # Internal: Fetch entries by UID.
        #
        # Returns an Array of Net::LDAP::Entry objects.
        def entries_by_uid(members)
          filter = members.map { |uid| Net::LDAP::Filter.eq(ldap.uid, uid) }.reduce(:|)
          domains.each_with_object([]) do |domain, entries|
            entries.concat domain.search(filter: filter, attributes: attrs)
          end.compact
        end
        private :entries_by_uid

        # Internal: Returns an Array of String DNs for `groupOfNames` and
        # `uniqueGroupOfNames` members.
        def member_dns(entry)
          MEMBERSHIP_NAMES.each_with_object([]) do |attr_name, members|
            members.concat entry[attr_name]
          end
        end
        private :member_dns

        # Internal: Returns an Array of String UIDs for PosixGroups members.
        def member_uids(entry)
          entry["memberUid"]
        end
        private :member_uids
      end
    end
  end
end
