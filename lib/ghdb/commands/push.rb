# frozen_string_literal: true

module Ghdb
  module Commands
    module Push
      GHDB_DIR = '.ghdb'
      DB_PATH  = "#{GHDB_DIR}/ghdb.sqlite"

      def self.run(opts)
        replica = opts[:replica] || replica_from_env

        unless replica
          warn 'Error: --replica is required or set GHDB_BUCKET (and optionally GHDB_ENDPOINT)'
          exit 1
        end

        unless File.exist?(DB_PATH)
          warn "Error: #{DB_PATH} not found. Run `ghdb build` first."
          exit 1
        end

        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        env = {
          'AWS_ACCESS_KEY_ID' => ENV['GHDB_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['GHDB_SECRET_ACCESS_KEY']
        }

        exec env, 'litestream', 'replicate', '-exec', 'echo done', DB_PATH, replica
      end

      def self.replica_from_env
        return nil unless ENV['GHDB_BUCKET'] && !ENV['GHDB_BUCKET'].empty?

        endpoint = ENV['GHDB_ENDPOINT'] || 'fly.storage.tigris.dev'
        "s3://#{ENV['GHDB_BUCKET']}?endpoint=#{endpoint}&region=auto"
      end
    end
  end
end
