# frozen_string_literal: true

module Ghdb
  module Commands
    module Cleanup
      def self.run(opts)
        local  = opts[:local] || opts[:all]
        remote = opts[:remote] || opts[:all]
        force  = opts[:force]

        unless local || remote
          warn <<~USAGE
            Usage:
              ghdb cleanup --local           # ローカルの .ghdb/ を削除
              ghdb cleanup --remote          # Tigris 上の DB を削除
              ghdb cleanup --all             # 両方削除
              ghdb cleanup --local --force   # 確認なしで削除
              ghdb cleanup --all --force     # 確認なしで両方削除
          USAGE
          exit 1
        end

        targets = []
        targets << 'local (.ghdb/)' if local
        targets << "remote (s3://#{ENV['GHDB_BUCKET'] || '?'})" if remote

        unless force
          print "This will delete: #{targets.join(', ')}. Are you sure? [y/N] "
          answer = $stdin.gets.to_s.strip.downcase
          unless answer == 'y'
            puts 'Aborted.'
            exit 0
          end
        end

        cleanup_local! if local
        cleanup_remote! if remote
      end

      def self.cleanup_local!
        ghdb_dir = Ghdb::Config::GHDB_DIR
        if Dir.exist?(ghdb_dir)
          FileUtils.rm_rf(ghdb_dir)
          puts "ghdb cleanup: deleted #{ghdb_dir}"
        else
          puts "ghdb cleanup: #{ghdb_dir} not found, skipping"
        end
      end

      def self.cleanup_remote!
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

        env = {
          'AWS_ACCESS_KEY_ID' => ENV['GHDB_ACCESS_KEY_ID'],
          'AWS_SECRET_ACCESS_KEY' => ENV['GHDB_SECRET_ACCESS_KEY']
        }

        if system(env, 'litestream', 'reset', replica, out: File::NULL, err: File::NULL)
          puts "ghdb cleanup: deleted #{replica}"
        else
          warn "ghdb cleanup: failed to delete #{replica}"
          exit 1
        end
      end
    end
  end
end
