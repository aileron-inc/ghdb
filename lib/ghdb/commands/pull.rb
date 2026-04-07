# frozen_string_literal: true

module Ghdb
  module Commands
    module Pull
      def self.run(_opts)
        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        unless Env.valid?
          warn "Error: missing environment variables: #{Env.missing_vars.join(', ')}"
          exit 1
        end

        db_path = Ghdb::Config.db_path

        unless db_path
          warn 'Error: GHDB_DATABASE_PATH is not set and config/database.yml has no ghdb entry.'
          warn '  Set GHDB_DATABASE_PATH in your .envrc or .env'
          exit 1
        end

        FileUtils.mkdir_p(File.dirname(db_path))

        config_path = Env.write_litestream_config(db_path)

        File.delete(db_path) if File.exist?(db_path)

        puts "ghdb pull: restoring from #{Env.replica_url}..."
        if system('litestream', 'restore', '-if-replica-exists', '-config', config_path, '-o', db_path, db_path)
          puts "ghdb pull: done (#{db_path})"
        else
          warn "Error: failed to restore from #{Env.replica_url}"
          exit 1
        end
      ensure
        File.delete(config_path) if config_path && File.exist?(config_path)
      end
    end
  end
end
