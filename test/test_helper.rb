__dir__ = File.expand_path(File.dirname(__FILE__))
__lib__ = File.expand_path('lib', File.dirname(__FILE__))

$LOAD_PATH << __dir__ unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH << __lib__ unless $LOAD_PATH.include?(__lib__)

require 'pathname'
FIXTURES = Pathname(File.expand_path('fixtures', __dir__))

require 'github/ldap'
require 'github/ldap/server'

require 'minitest/autorun'

class GitHub::Ldap::Test < Minitest::Test
  def self.test_env
    ENV['TESTENV'] || "apacheds"
  end

  def self.run(reporter, options = {})
    start_server
    super
    stop_server
  end

  def self.stop_server
    if test_env == "apacheds"
      GitHub::Ldap.stop_server
    end
  end

  def self.start_server
    if test_env == "apacheds"
      server_opts = respond_to?(:test_server_options) ? test_server_options : {}
      GitHub::Ldap.start_server(server_opts)
    end
  end

  def options
    @service   = MockInstrumentationService.new
    @options ||=
      case self.class.test_env
      when "apacheds"
        GitHub::Ldap.server_options.merge \
          host: 'localhost',
          uid:  'uid',
          instrumentation_service: @service
      when "openldap"
        {
          host: 'localhost',
          port: 389,
          admin_user:     'uid=admin,dc=github,dc=com',
          admin_password: 'passworD1',
          search_domains: %w(dc=github,dc=com),
          uid: 'uid',
          instrumentation_service: @service
        }
      end
  end
end

class GitHub::Ldap::UnauthenticatedTest < GitHub::Ldap::Test
  def self.start_server
    if test_env == "apacheds"
      GitHub::Ldap.start_server(:allow_anonymous => true)
    end
  end

  def options
    @options ||= begin
      super.delete_if {|k, _| [:admin_user, :admin_password].include?(k)}
    end
  end
end

class MockInstrumentationService
  def initialize
    @events = {}
  end

  def instrument(event, payload)
    result = yield(payload)
    @events[event] ||= []
    @events[event] << [payload, result]
    result
  end

  def subscribe(event)
    @events[event] ||= []
    @events[event]
  end
end
