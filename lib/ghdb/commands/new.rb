# frozen_string_literal: true

module Ghdb
  module Commands
    module New
      def self.run(opts)
        unless opts[:repo]
          warn 'Usage: ghdb new --repo OWNER/NAME [--branch BRANCH]'
          exit 1
        end

        owner, name = opts[:repo].split('/', 2)
        unless owner && name
          warn 'Error: --repo must be in OWNER/NAME format'
          exit 1
        end

        branch = opts[:branch] || 'main'

        FileUtils.mkdir_p(Ghdb::Config::GHDB_DIR)
        Ghdb.connect(database: Ghdb::Config.db_path)

        if Ghdb::Repository.exists?(owner: owner, name: name)
          warn "Error: repository #{opts[:repo]} already registered"
          exit 1
        end

        Ghdb::Repository.create!(owner: owner, name: name, default_branch: branch)
        puts "ghdb: registered #{opts[:repo]}"

        config_path = Ghdb::Config::CONFIG_PATH
        if File.exist?(config_path)
          warn "Warning: #{config_path} already exists, skipping"
        else
          File.write(config_path, <<~YAML)
            repo: #{opts[:repo]}
            branch: #{branch}
          YAML
          puts "ghdb: created #{config_path}"
        end
      end
    end
  end
end
