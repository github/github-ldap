module GitHub
  class Ldap

    # A simple cache of GitHub::Ldap objects to prevent creating multiple
    # instances of connections that point to the same URI/host.
    class ConnectionCache

      # Public - Create or return cached instance of GitHub::Ldap created with options,
      # where the cache key is the value of options[:host].
      #
      # options - Initialization attributes suitable for creating a new connection with
      # GitHub::Ldap.new(options)
      #
      # Returns true or false.
      def self.get_connection(options={})
        @cache ||= self.new
        @cache.get_connection(options)
      end

      def get_connection(options)
        @connections ||= {}
        @connections[options[:host]] ||= GitHub::Ldap.new(options)
      end
    end
  end
end
