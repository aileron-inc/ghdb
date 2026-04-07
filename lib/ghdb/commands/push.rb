# frozen_string_literal: true

module Ghdb
  module Commands
    module Push
      GHDB_DIR = '.ghdb'
      DB_PATH  = "#{GHDB_DIR}/ghdb.sqlite"

      def self.run(_opts)
        unless File.exist?(DB_PATH)
          warn "Error: #{DB_PATH} not found. Run `ghdb build` first."
          exit 1
        end

        unless system('which litestream > /dev/null 2>&1')
          warn 'Error: litestream is not installed. See https://litestream.io/install'
          exit 1
        end

        unless Env.valid?
          warn "Error: missing environment variables: #{Env.missing_vars.join(', ')}"
          exit 1
        end

        config_path = Env.write_litestream_config(DB_PATH)
        push!(config_path)
      ensure
        File.delete(config_path) if config_path && File.exist?(config_path)
      end

      def self.push!(config_path)
        # litestream を起動してログを監視し、compaction complete で終了する
        rd, wr = IO.pipe

        pid = spawn('litestream', 'replicate', '-config', config_path, err: wr, out: wr)
        wr.close

        rd.each_line do |line|
          $stdout.print line
          $stdout.flush
          if line.include?('compaction complete')
            Process.kill('TERM', pid)
            break
          end
        end

        Process.wait(pid)
      end
    end
  end
end
