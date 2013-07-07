__dir__ = File.expand_path(File.dirname(__FILE__))
__lib__ = File.expand_path('lib', File.dirname(__FILE__))

$LOAD_PATH << __dir__ unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH << __lib__ unless $LOAD_PATH.include?(__lib__)

require 'github/ldap'
require 'github/ldap/server'

require 'minitest/autorun'
