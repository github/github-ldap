module GitHub
  class Ldap
    # A domain represents the base object for an ldap tree.
    # It encapsulates the operations that you can perform against a tree, authenticating users, for instance.
    #
    # This makes possible to reuse a server connection to perform operations with two different domain bases.
    #
    # To get a domain, you'll need to create a `Ldap` object and then call the method `domain` with the name of the base.
    #
    # For example:
    #
    # domain = GitHub::Ldap.new(options).domain("dc=github,dc=com")
    #
    class Domain
      include Filter

      def initialize(ldap, base_name, uid)
        @ldap, @base_name, @uid = ldap, base_name, uid
      end

      # List all groups under this tree, including subgroups.
      #
      # Returns a list of ldap entries.
      def all_groups
        search(filter: ALL_GROUPS_FILTER)
      end

      # List all groups under this tree that match the query.
      #
      # query: is the partial name to filter for.
      # opts: additional options to filter with. It's specially recommended to restrict this search by size.
      # block: is an optional block to pass to the search.
      #
      # Returns a list of ldap entries.
      def filter_groups(query, opts = {}, &block)
        search(opts.merge(filter: group_contains_filter(query)), &block)
      end

      # List the groups in the ldap server that match the configured ones.
      #
      # group_names: is an array of group CNs.
      #
      # Returns a list of ldap entries for the configured groups.
      def groups(group_names)
        search(filter: group_filter(group_names))
      end

      # List the groups that a user is member of.
      #
      # user_entry: is the entry for the user in the server.
      # group_names: is an array of group CNs.
      #
      # Return an Array with the groups that the given user is member of that belong to the given group list.
      def membership(user_entry, group_names)
        if @ldap.virtual_attributes.enabled? || @ldap.recursive_group_search_fallback?
          all_groups = search(filter: group_filter(group_names))
          groups_map = all_groups.each_with_object({}) {|entry, hash| hash[entry.dn] = entry}

          if @ldap.virtual_attributes.enabled?
            member_of = groups_map.keys & user_entry[@ldap.virtual_attributes.virtual_membership]
            member_of.map {|dn| groups_map[dn]}
          else # recursive group search fallback
            groups_map.each_with_object([]) do |(dn, group_entry), acc|
              acc << group_entry if @ldap.load_group(group_entry).is_member?(user_entry)
            end
          end
        else
          # fallback to non-recursive group membership search
          filter = member_filter(user_entry)

          # include memberUid filter if enabled and entry has a UID set
          if @ldap.posix_support_enabled? && !user_entry[@ldap.uid].empty?
            filter |= posix_member_filter(user_entry, @ldap.uid)
          end

          filter &= group_filter(group_names)
          search(filter: filter)
        end
      end

      # Check if the user is include in any of the configured groups.
      #
      # user_entry: is the entry for the user in the server.
      # group_names: is an array of group CNs.
      #
      # Returns true if the user belongs to any of the groups.
      # Returns false otherwise.
      def is_member?(user_entry, group_names)
        return true if group_names.nil?
        return true if group_names.empty?

        user_membership = membership(user_entry, group_names)

        !user_membership.empty?
      end

      # Check if the user credentials are valid.
      #
      # login: is the user's login.
      # password: is the user's password.
      #
      # Returns a Ldap::Entry if the credentials are valid.
      # Returns nil if the credentials are invalid.
      def valid_login?(login, password)
        if user = user?(login) and auth(user, password)
          return user
        end
      end

      # Check if a user exists based in the `uid`.
      #
      # login: is the user's login
      # search_options: Net::LDAP#search compatible options to pass through
      #
      # Returns the user if the login matches any `uid`.
      # Returns nil if there are no matches.
      def user?(login, search_options = {})
        @ldap.user_search_strategy.perform(login, @base_name, @uid, search_options).first
      end

      # Check if a user can be bound with a password.
      #
      # user: is a ldap entry representing the user.
      # password: is the user's password.
      #
      # Returns true if the user can be bound.
      def auth(user, password)
        @ldap.bind(method: :simple, username: user.dn, password: password)
      end

      # Authenticate a user with the ldap server.
      #
      # login: is the user's login. This method doesn't accept email identifications.
      # password: is the user's password.
      # group_names: is an array of group CNs.
      #
      # Returns the user info if the credentials are valid and there are no groups configured.
      # Returns the user info if the credentials are valid and the user belongs to a configured group.
      # Returns nil if the credentials are invalid
      def authenticate!(login, password, group_names = nil)
        user = valid_login?(login, password)

        return user if user && is_member?(user, group_names)
      end

      # Search entries using this domain as base.
      #
      # options: is a Hash with the options for the search. The base option is always overriden.
      # block: is an optional block to pass to the search.
      #
      # Returns an array with the entries found.
      def search(options, &block)
        options[:base] = @base_name
        options[:attributes] ||= []
        options[:paged_searches_supported] = true

        @ldap.search(options, &block)
      end

      # Get the entry for this domain.
      #
      # Returns a Net::LDAP::Entry
      def bind(options = {})
        options[:size]  = 1
        options[:scope] = Net::LDAP::SearchScope_BaseObject
        options[:attributes] ||= []
        search(options).first
      end
    end
  end
end
