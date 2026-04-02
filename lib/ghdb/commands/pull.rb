# frozen_string_literal: true

module Ghdb
  module Commands
    module Pull
      def self.run(opts)
        bucket   = ENV['GHDB_BUCKET']
        endpoint = ENV['GHDB_ENDPOINT'] || 'fly.storage.tigris.dev'
        replica  = opts[:replica] || (bucket && "s3://#{bucket}?endpoint=#{endpoint}&region=auto")

        unless replica
          warn 'Error: --replica is required or set GHDB_BUCKET (and optionally GHDB_ENDPOINT)'
          exit 1
        end

        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        db_path = Ghdb::Config.db_path
        FileUtils.mkdir_p(Ghdb::Config::GHDB_DIR)

        env = {
          'AWS_ACCESS_KEY_ID' => ENV['GHDB_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['GHDB_SECRET_ACCESS_KEY']
        }

        puts "ghdb pull: restoring from #{replica}..."
        if system(env, 'litestream', 'restore', '-if-replica-exists', '-o', db_path, replica)
          puts "ghdb pull: done (#{db_path})"
        else
          warn "Error: failed to restore from #{replica}"
          exit 1
        end
      end
    end
  end
end
