module GitHub
  class Ldap
    # Manages the filters and attributes used for queries.
    #
    ## Queries
    #
    # These are the queries accounted for:
    #
    # * user lookup
    # * group lookup
    # * group search
    # * group member search (nested)
    # * group membership validation (nested)
    # * user membership lookup (nested)
    #
    # Queries marked with *(nested)* may require recursion.
    #
    # This object is responsible for generating the query filter based on the
    # given input.
    #
    ## Usage
    #
    #     fs = FilterSet.new(ldap, cn: "cn", member: "member")
    #     fs.attributes[:member] #=> "member"
    #
    #     fs.group_filter(cn) #=> Net::LDAP::Filter(objectClass=group&cn=#{cn})
    #
    #     fs.member_search_filter(dn) #=> Net::LDAP::Filter(memberOf=#{dn})
    #     fs.member_search_filter = "(&(memberOf:#{OID}:=%s)(objectClass=person))"
    #
    #     fs.person_filter #=> Net::LDAP::Filter(objectClass=person)
    #     fs.person_filter = "(&(sAMAccountName=%s)(description=git)(objectCategory=person))"
    class FilterSet
    end
  end
end
