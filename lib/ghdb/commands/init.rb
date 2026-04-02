# frozen_string_literal: true

module Ghdb
  module Commands
    module Init
      REQUIRED_ENV = %w[GHDB_ACCESS_KEY_ID GHDB_SECRET_ACCESS_KEY GHDB_BUCKET].freeze

      def self.run
        check_litestream!
        check_env!

        FileUtils.mkdir_p(Ghdb::Config::GHDB_DIR)

        db_path  = Ghdb::Config.db_path
        endpoint = ENV['GHDB_ENDPOINT'] || 'fly.storage.tigris.dev'
        replica  = "s3://#{ENV['GHDB_BUCKET']}?endpoint=#{endpoint}&region=auto"
        env      = litestream_env

        if replica_exists?(db_path, replica, env)
          puts "ghdb: already exists (#{ENV['GHDB_BUCKET']})"
        else
          Ghdb.connect(database: db_path)
          push!(db_path, replica, env)
          puts "ghdb: initialized (#{ENV['GHDB_BUCKET']})"
        end
      end

      def self.check_litestream!
        return if system('which litestream > /dev/null 2>&1')

        warn 'Error: litestream is not installed. See https://litestream.io/install'
        exit 1
      end

      def self.check_env!
        missing = REQUIRED_ENV.reject { |k| ENV[k] && !ENV[k].empty? }
        return if missing.empty?

        warn "Error: missing environment variables: #{missing.join(', ')}"
        exit 1
      end

      def self.litestream_env
        {
          'AWS_ACCESS_KEY_ID' => ENV['GHDB_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['GHDB_SECRET_ACCESS_KEY']
        }
      end

      def self.replica_exists?(db_path, replica, env)
        system(env, 'litestream', 'restore', '-if-replica-exists', '-o', db_path, replica,
               out: File::NULL, err: File::NULL)
      end

      def self.push!(db_path, replica, env)
        system(env, 'litestream', 'replicate', '-exec', 'echo done', db_path, replica)
      end
    end
  end
end
