# frozen_string_literal: true

require 'digest'
require 'yaml'

module Ghdb
  module Commands
    module Build
      def self.run(_opts)
        config   = load_config
        repo_str = config['repo']

        owner, name = repo_str.split('/', 2)
        unless owner && name
          warn 'Error: repo must be in OWNER/NAME format'
          exit 1
        end

        Ghdb.connect(database: Ghdb::Config.db_path)

        repo = Ghdb::Repository.find_by(owner: owner, name: name)
        unless repo
          warn "Error: repository #{repo_str} not found. Run `ghdb new --repo #{repo_str}` first."
          exit 1
        end

        dir   = File.expand_path('.')
        files = repo.synced_at ? changed_files(dir) : all_files(dir)

        upserted = 0
        deleted  = 0

        files.each do |relative_path|
          full_path = File.join(dir, relative_path)

          unless File.exist?(full_path)
            entry = repo.blob_entries.find_by(path: relative_path)
            if entry
              entry.destroy
              deleted += 1
            end
            next
          end

          content = File.read(full_path, encoding: 'utf-8')
          sha     = Digest::SHA1.hexdigest(content)

          entry = repo.blob_entries.find_or_initialize_by(path: relative_path)
          next if entry.persisted? && entry.sha == sha

          frontmatter, body = parse_frontmatter(content)
          entry.assign_attributes(sha: sha, content: body, frontmatter: frontmatter)
          entry.save!
          upserted += 1
        end

        repo.update!(synced_at: Time.now)
        puts "ghdb build done: #{upserted} upserted, #{deleted} deleted (#{repo_str})"
      end

      def self.load_config
        config_path = Ghdb::Config::CONFIG_PATH
        unless File.exist?(config_path)
          warn "Error: #{config_path} not found. Run `ghdb new --repo OWNER/NAME` first."
          exit 1
        end

        YAML.safe_load(File.read(config_path))
      end

      def self.changed_files(dir)
        `git -C #{dir} diff --name-only HEAD~1 HEAD 2>/dev/null`.split("\n")
      end

      def self.all_files(dir)
        `git -C #{dir} ls-files 2>/dev/null`.split("\n")
      end

      def self.parse_frontmatter(content)
        parsed = FrontMatterParser::Parser.new(:md).call(content)
        [parsed.front_matter, parsed.content]
      rescue StandardError
        [{}, content]
      end
    end
  end
end
