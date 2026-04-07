# frozen_string_literal: true

require 'yaml'
require 'erb'

module Ghdb
  module Config
    GHDB_DIR    = '.ghdb'
    CONFIG_PATH = "#{GHDB_DIR}/config.yml"

    def self.db_path
      ENV['GHDB_DATABASE_PATH'] || db_path_from_database_yml
    end

    # config/database.yml の ghdb エントリから database パスを読む
    def self.db_path_from_database_yml
      yml_path = 'config/database.yml'
      return nil unless File.exist?(yml_path)

      env = ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'

      # Rails.root が未定義の場合は現在のディレクトリで代替する
      rails_root = defined?(Rails) ? Rails.root.to_s : Dir.pwd
      b = binding
      b.local_variable_set(:rails_root_str, rails_root)

      content = File.read(yml_path)
      # Rails.root を文字列に置換してから ERB 展開する
      content = content.gsub('Rails.root', "Pathname.new(\"#{rails_root}\")")

      require 'pathname'
      config = YAML.safe_load(ERB.new(content).result(b), permitted_classes: [Symbol], aliases: true)
      db = config.dig(env, 'ghdb', 'database') || config.dig('ghdb', 'database')
      db&.strip&.then { |p| p.empty? ? nil : p }
    rescue StandardError
      nil
    end
  end
end
