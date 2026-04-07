# frozen_string_literal: true

module Ghdb
  module Commands
    module Init
      def self.run
        check_litestream!
        check_env!

        FileUtils.mkdir_p(Ghdb::Config::GHDB_DIR)

        db_path = Ghdb::Config.db_path

        if replica_exists?(db_path)
          puts "ghdb: already exists (#{Env.bucket})"
        else
          Ghdb.connect(database: db_path)
          push!(db_path)
          puts "ghdb: initialized (#{Env.bucket})"
        end
      end

      def self.check_litestream!
        return if system('which litestream > /dev/null 2>&1')

        warn 'Error: litestream is not installed. See https://litestream.io/install'
        exit 1
      end

      def self.check_env!
        return if Env.valid?

        warn "Error: missing environment variables: #{Env.missing_vars.join(', ')}"
        exit 1
      end

      def self.replica_exists?(db_path)
        config_path = Env.write_litestream_config(db_path)
        system('litestream', 'restore', '-if-replica-exists', '-config', config_path, '-o', db_path, db_path,
               out: File::NULL, err: File::NULL)
      ensure
        File.delete(config_path) if config_path && File.exist?(config_path)
      end

      def self.push!(db_path)
        config_path = Env.write_litestream_config(db_path)
        system('litestream', 'replicate', '-config', config_path, '-exec', 'echo done')
      ensure
        File.delete(config_path) if config_path && File.exist?(config_path)
      end
    end
  end
end
