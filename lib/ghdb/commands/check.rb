# frozen_string_literal: true

module Ghdb
  module Commands
    module Check
      def self.run
        check_litestream!
        check_env!
        check_remote!
      end

      def self.check_litestream!
        if system('which litestream > /dev/null 2>&1')
          puts 'OK: litestream found'
        else
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end
      end

      def self.check_env!
        if Env.valid?
          puts 'OK: environment variables set'
        else
          warn "Error: missing environment variables: #{Env.missing_vars.join(', ')}"
          exit 1
        end
      end

      def self.check_remote!
        tmp_path    = "/tmp/ghdb-check-#{Process.pid}.sqlite"
        config_path = Env.write_litestream_config(tmp_path)

        result = system('litestream', 'restore', '-if-replica-exists', '-config', config_path, '-o', tmp_path, tmp_path)

        if result && File.exist?(tmp_path)
          puts "OK: #{Env.replica_url} (found)"
        elsif result
          puts "OK: #{Env.replica_url} (not yet created)"
        else
          warn "Error: failed to connect to #{Env.replica_url}"
          exit 1
        end
      ensure
        File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
        File.delete(config_path) if config_path && File.exist?(config_path)
      end
    end
  end
end
