module GitHub
  class Ldap
    require 'ladle'

    # Preconfigured user fixtures. If you want to use them for your own tests.
    DEFAULT_FIXTURES_PATH = File.expand_path('fixtures.ldif', File.dirname(__FILE__))

    DEFAULT_SERVER_OPTIONS = {
      user_fixtures:  DEFAULT_FIXTURES_PATH,
      user_domain:    'dc=github,dc=com',
      admin_user:     'uid=admin,dc=github,dc=com',
      admin_password: 'secret',
      quiet:          true,
      port:           3897
    }

    class << self

      # server_options: is the options used to start the server,
      #                 useful to know in development.
      attr_reader :server_options

      # ldap_server: is the instance of the testing ldap server,
      #              you should never interact with it,
      #              but it's used to grecefully stop it after your tests finalize.
      attr_reader :ldap_server
    end

    # Start a testing server.
    # If there is already a server initialized it doesn't do anything.
    #
    # options: is a hash with the custom options for the server.
    def self.start_server(options = {})
      @server_options = DEFAULT_SERVER_OPTIONS.merge(options)

      @server_options[:allow_anonymous] ||= false
      @server_options[:ldif]              = @server_options[:user_fixtures]
      @server_options[:domain]            = @server_options[:user_domain]
      @server_options[:tmpdir]          ||= server_tmp

      @server_options[:quiet] = false if @server_options[:verbose]

      @ldap_server = Ladle::Server.new(@server_options)
      @ldap_server.start
    end

    # Stop the testing server.
    # If there is no server started this method doesn't do anything.
    def self.stop_server
      ldap_server && ldap_server.stop
    end

    # Determine the temporal directory where the ldap server lives.
    # If there is no temporal directory in the environment we create one in the base path.
    #
    # Returns the path to the temporal directory.
    def self.server_tmp
      tmp = ENV['TMPDIR'] || ENV['TEMPDIR']

      if tmp.nil?
        tmp = 'tmp'
        Dir.mkdir(tmp) unless File.directory?('tmp')
      end

      tmp
    end
  end
end
