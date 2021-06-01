__dir__ = File.expand_path(File.dirname(__FILE__))
__lib__ = File.expand_path('lib', File.dirname(__FILE__))

$LOAD_PATH << __dir__ unless $LOAD_PATH.include?(__dir__)
$LOAD_PATH << __lib__ unless $LOAD_PATH.include?(__lib__)

require 'pathname'
FIXTURES = Pathname(File.expand_path('fixtures', __dir__))

require 'github/ldap'
require 'github/ldap/server'

require 'minitest/mock'
require 'minitest/autorun'

require 'mocha/minitest'

if ENV.fetch('TESTENV', "apacheds") == "apacheds"
  # Make sure we clean up running test server
  # NOTE: We need to do this manually since its internal `at_exit` hook
  # collides with Minitest's autorun at_exit handling, hence this hook.
  Minitest.after_run do
    GitHub::Ldap.stop_server
  end
end

class GitHub::Ldap::Test < Minitest::Test
  def self.test_env
    ENV.fetch("TESTENV", "apacheds")
  end

  def self.run(reporter, options = {})
    start_server
    super
    stop_server
  end

  def self.stop_server
    if test_env == "apacheds"
      # see Minitest.after_run hook above.
      # GitHub::Ldap.stop_server
    end
  end

  def self.test_server_options
    {
      custom_schemas:   FIXTURES.join('posixGroup.schema.ldif').to_s,
      user_fixtures:    FIXTURES.join('common/seed.ldif').to_s,
      allow_anonymous:  true,
      verbose:          ENV.fetch("VERBOSE", "0") == "1"
    }
  end

  def self.start_server
    if test_env == "apacheds"
      # skip this if a server has already been started
      return if GitHub::Ldap.ldap_server

      GitHub::Ldap.start_server(test_server_options)
    end
  end

  def options
    @service   = MockInstrumentationService.new
    @options ||=
      case self.class.test_env
      when "apacheds"
        GitHub::Ldap.server_options.merge \
          admin_user: 'uid=admin,dc=github,dc=com',
          admin_password: 'passworD1',
          host: 'localhost',
          uid:  'uid',
          instrumentation_service: @service
      when "openldap"
        {
          host: ENV.fetch("INTEGRATION_HOST", "localhost"),
          port: 389,
          admin_user:     'uid=admin,dc=github,dc=com',
          admin_password: 'passworD1',
          search_domains: %w(dc=github,dc=com),
          uid: 'uid',
          instrumentation_service: @service
        }
      when "activedirectory"
        {
          host: ENV.fetch("INTEGRATION_HOST"),
          port: ENV.fetch("INTEGRATION_PORT", 389),
          admin_user: ENV.fetch("INTEGRATION_USER"),
          admin_password: ENV.fetch("INTEGRATION_PASSWORD"),
          search_domains: ENV.fetch("INTEGRATION_SEARCH_DOMAINS"),
          instrumentation_service: @service
        }
      end
  end
end

class GitHub::Ldap::UnauthenticatedTest < GitHub::Ldap::Test
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
