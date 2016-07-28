 ldapsearch -x -h dc4.ghe.local \
 -b "CN=Maggie Mae,CN=Users,DC=dc4,DC=ghe,DC=local" \
 -D "GHE\Administrator" -w "vagrant" \
 "(|(|(| \
 (memberOf:1.2.840.113556.1.4.1941:=CN=ghe-users,CN=Users,DC=ghe,DC=local) \
 (memberOf:1.2.840.113556.1.4.1941:=CN=ghe-users,CN=Users, DC=dc4,DC=ghe,DC=local)) \
 (memberOf:1.2.840.113556.1.4.1941:=CN=ghe-admins,CN=Users,DC=ghe,DC=local)) \
 (memberOf:1.2.840.113556.1.4.1941:=CN=ghe-admins,CN=Users,DC=dc4,DC=ghe,DC=local))"

