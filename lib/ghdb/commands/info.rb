# frozen_string_literal: true

module Ghdb
  module Commands
    module Info
      def self.run(opts)
        if opts[:remote]
          run_remote
        else
          run_local
        end
      end

      def self.run_local
        db_path  = Ghdb::Config.db_path
        bucket   = ENV['GHDB_BUCKET']
        endpoint = ENV['GHDB_ENDPOINT'] || 'fly.storage.tigris.dev'

        unless File.exist?(db_path)
          warn "Error: #{db_path} not found. Run `ghdb init` and `ghdb build` first."
          exit 1
        end

        Ghdb.connect(database: db_path)
        print_info(db_path, bucket, endpoint)
      end

      def self.run_remote
        bucket   = ENV['GHDB_BUCKET']
        endpoint = ENV['GHDB_ENDPOINT'] || 'fly.storage.tigris.dev'
        replica  = "s3://#{bucket}?endpoint=#{endpoint}&region=auto"

        unless bucket && !bucket.empty?
          warn 'Error: GHDB_BUCKET is not set'
          exit 1
        end

        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        tmp_path = "/tmp/ghdb-info-#{Process.pid}.sqlite"
        env      = {
          'AWS_ACCESS_KEY_ID' => ENV['GHDB_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['GHDB_SECRET_ACCESS_KEY']
        }

        unless system(env, 'litestream', 'restore', '-if-replica-exists', '-o', tmp_path, replica)
          warn "Error: failed to restore from #{replica}"
          exit 1
        end

        unless File.exist?(tmp_path)
          puts "No remote DB found at #{replica}"
          return
        end

        Ghdb.connect(database: tmp_path)
        puts '(remote)'
        print_info(tmp_path, bucket, endpoint)
      ensure
        File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
      end

      def self.print_info(db_path, bucket, endpoint)
        puts "db:      #{db_path} (#{File.size(db_path)} bytes)"
        if bucket
          puts "replica: s3://#{bucket}?endpoint=#{endpoint}&region=auto"
          puts "console: https://console.storage.dev/buckets/#{bucket}/objects"
        else
          puts 'replica: (GHDB_BUCKET not set)'
        end
        puts

        Ghdb::Repository.order(:owner, :name).each do |repo|
          count  = repo.blob_entries.count
          synced = repo.synced_at ? repo.synced_at.strftime('%Y-%m-%d %H:%M:%S') : 'never'
          puts "#{repo.owner}/#{repo.name}"
          puts "  branch:    #{repo.default_branch}"
          puts "  entries:   #{count}"
          puts "  synced_at: #{synced}"
        end
      end
    end
  end
end
