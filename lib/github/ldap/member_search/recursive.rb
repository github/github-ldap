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
          domains.each_with_object([]) do |domain, members|
            domain.search(base: group.dn, filter: ALL_GROUPS_FILTER, attributes: attrs) do |subgroup|
              members.concat member_dns(subgroup)
              members.concat member_uids(subgroup)
            end
          end.uniq.compact.map do |dn|
            # NOTE: keeps API backwards compatible
            Net::LDAP::Entry.new(dn)
          end
        end

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
