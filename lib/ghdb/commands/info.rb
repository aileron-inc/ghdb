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
        db_path = Ghdb::Config.db_path

        unless File.exist?(db_path)
          warn "Error: #{db_path} not found. Run `ghdb init` and `ghdb build` first."
          exit 1
        end

        Ghdb.connect(database: db_path)
        print_info(db_path)
      end

      def self.run_remote
        replica = Env.replica_url

        unless replica
          warn 'Error: bucket not set (GHDB_BUCKET, TIGRIS_BUCKET, or BUCKET_NAME)'
          exit 1
        end

        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        tmp_path = "/tmp/ghdb-info-#{Process.pid}.sqlite"

        unless system(Env.credentials_env, 'litestream', 'restore', '-if-replica-exists', '-o', tmp_path, replica)
          warn "Error: failed to restore from #{replica}"
          exit 1
        end

        unless File.exist?(tmp_path)
          puts "No remote DB found at #{replica}"
          return
        end

        Ghdb.connect(database: tmp_path)
        puts '(remote)'
        print_info(tmp_path)
      ensure
        File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
      end

      def self.print_info(db_path)
        puts "db:      #{db_path} (#{File.size(db_path)} bytes)"
        if Env.bucket
          puts "replica: #{Env.replica_url}"
          puts "console: https://console.storage.dev/buckets/#{Env.bucket}/objects"
        else
          puts 'replica: (bucket not set)'
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
