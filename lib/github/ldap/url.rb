module GitHub
  class Ldap

    # This class represents an LDAP URL
    #
    # See: https://tools.ietf.org/html/rfc4516#section-2
    #      https://docs.oracle.com/cd/E19957-01/817-6707/urls.html
    #
    class URL
      extend Forwardable
      SCOPES = {
        "base" => Net::LDAP::SearchScope_BaseObject,
        "one" => Net::LDAP::SearchScope_SingleLevel,
        "sub" => Net::LDAP::SearchScope_WholeSubtree
      }
      SCOPES.default = Net::LDAP::SearchScope_BaseObject

      attr_reader :dn, :attributes, :scope, :filter

      def_delegators :@uri, :port, :host, :scheme

      # Public - Creates a new GitHub::Ldap::URL object with :port, :host and :scheme
      # delegated to a URI object parsed from url_string, and then parses the
      # query params according to the LDAP specification.
      #
      # url_string  - An LDAP URL string.
      # returns     - a GitHub::Ldap::URL with the following attributes:
      #   host         - Name or IP of the LDAP server.
      #   port         - The given port, defaults to 389.
      #   dn           - The base search DN.
      #   attributes   - The comma-delimited list of attributes to be returned.
      #   scope        - The scope of the search.
      #   filter       - Search filter to apply to entries within the specified scope of the search.
      #
      # Supported LDAP URL strings look like this, where sections in brackets are optional:
      #
      #          ldap[s]://[hostport][/[dn[?[attributes][?[scope][?[filter]]]]]]
      #
      #      where:
      #
      #          hostport is a host name with an optional ":portnumber"
      #          dn is the base DN to be used for an LDAP search operation
      #          attributes is a comma separated list of attributes to be retrieved
      #          scope is one of these three strings: base one sub (default=base)
      #          filter is LDAP search filter as used in a call to ldap_search
      #
      #      For example:
      #
      #      ldap://dc4.ghe.local:456/CN=Maggie,DC=dc4,DC=ghe,DC=local?cn,mail?base?(cn=Charlie)
      #
      def initialize(url_string)
        if !self.class.valid?(url_string)
          raise InvalidLdapURLException.new("Invalid LDAP URL: #{url_string}")
        end
        @uri = URI(url_string)
        @dn = URI.unescape(@uri.path.sub(/^\//, ""))
        if @uri.query
          @attributes, @scope, @filter = @uri.query.split("?")
        end
      end

      def self.valid?(url_string)
        url_string =~ URI::regexp && ["ldap", "ldaps"].include?(URI(url_string).scheme)
      end

      # Maps the returned scope value from the URL to one of Net::LDAP::Scopes
      #
      # The URL scope value can be one of:
      #     "base" - retrieves information only about the DN (base_dn) specified.
      #     "one"  - retrieves information about entries one level below the DN (base_dn) specified. The base entry is not included in this scope.
      #     "sub"  - retrieves information about entries at all levels below the DN (base_dn) specified. The base entry is included in this scope.
      #
      # Which will map to one of the following Net::LDAP::Scopes:
      #   SearchScope_BaseObject   = 0
      #   SearchScope_SingleLevel  = 1
      #   SearchScope_WholeSubtree = 2
      #
      # If no scope or an invalid scope is given, defaults to SearchScope_BaseObject
      def net_ldap_scope
        Net::LDAP::SearchScopes[SCOPES[scope]]
      end

      class InvalidLdapURLException < Exception; end
    end
  end
end

