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
          # track groups found
          found = Hash.new

          # track all DNs searched for (so we don't repeat searches)
          searched = Set.new

          # if this is a posixGroup, return members immediately (no nesting)
          uids = member_uids(group)
          return entries_by_uid(uids) if uids.any?

          # track group
          searched << group.dn
          found[group.dn] = group

          # pull out base group's member DNs
          dns = member_dns(group)

          # search for base group's subgroups
          groups = dns.each_with_object([]) do |dn, groups|
            groups.concat find_groups_by_dn(dn)
            searched << dn
          end

          # track found groups
          groups.each { |g| found[g.dn] = g }

          # recursively find subgroups
          unless groups.empty?
            depth.times do |n|
              # pull out subgroups' member DNs to search through
              sub_dns = groups.each_with_object([]) do |subgroup, sub_dns|
                sub_dns.concat member_dns(subgroup)
              end

              # filter out if already searched for
              sub_dns.reject! { |dn| searched.include?(dn) }

              # give up if there's nothing else to search for
              break if sub_dns.empty?

              # search for subgroups
              subgroups = sub_dns.each_with_object([]) do |dn, subgroups|
                subgroups.concat find_groups_by_dn(dn)
                searched << dn
              end

              # give up if there were no subgroups found
              break if subgroups.empty?

              # track found subgroups
              subgroups.each { |g| found[g.dn] = g }

              # descend another level
              groups = subgroups
            end
          end

          # entries to return
          entries  = []

          # collect all member DNs, discarding dupes and subgroup DNs
          members = found.values.each_with_object([]) do |group, dns|
            entries << group
            dns.concat member_dns(group)
          end.uniq.reject { |dn| found.key?(dn) }

          # wrap member DNs in Net::LDAP::Entry objects
          entries.concat members.map! { |dn| Net::LDAP::Entry.new(dn) }

          entries
        end

        # Internal: Search for Groups by DN.
        #
        # Given a Distinguished Name (DN) String value, find the Group entry
        # that matches it. The DN may map to a `person` entry, but we want to
        # filter those out.
        #
        # This will find zero or one entry most of the time, but it's not
        # guaranteed so we account for the possibility of more.
        #
        # This method is intended to be used with `Array#concat` by the caller.
        #
        # Returns an Array of zero or more Net::LDAP::Entry objects.
        def find_groups_by_dn(dn)
          ldap.search \
            base: dn,
            scope: Net::LDAP::SearchScope_BaseObject,
            attributes: attrs,
            filter: ALL_GROUPS_FILTER
        end
        private :find_groups_by_dn

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
