__dir__ = File.expand_path(File.dirname(__FILE__))
__lib__ = File.expand_path('lib', File.dirname(__FILE__))

$LOAD_PATH << __dir__ unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH << __lib__ unless $LOAD_PATH.include?(__lib__)

require 'github/ldap'
require 'github/ldap/server'

require 'minitest/autorun'

class GitHub::Ldap::Test < Minitest::Test
  def self.run(reporter, options = {})
    start_server
    super
    stop_server
  end

  def self.stop_server
    GitHub::Ldap.stop_server
  end

  def self.start_server
    GitHub::Ldap.start_server
  end

  def options
    @options ||= GitHub::Ldap.server_options.merge \
      host: 'localhost',
      uid:  'uid'
  end
end

class GitHub::Ldap::UnauthenticatedTest < GitHub::Ldap::Test
  def self.start_server
    GitHub::Ldap.start_server(:allow_anonymous => true)
  end

  def options
    @options ||= begin
      super.delete_if {|k, _| [:admin_user, :admin_password].include?(k)}
    end
  end
end
