module GitHub
  class Ldap
    class ConnectionPool

      # Public - Create or return cached instance of GitHub::Ldap created with options,
      # where the cache key is the value of options[:host].
      #
      # Returns an instance of GitHub::Ldap
      def self.get_connection(options={})
        @instance ||= self.new
        @instance.get_connection(options)
      end

      def get_connection(options)
        host = options[:host]
        @connections ||= Hash.new do |cache, host|
          conn =  GitHub::Ldap.new(options)
          cache[host] = conn
        end
        @connections[host]
      end
    end
  end
end
