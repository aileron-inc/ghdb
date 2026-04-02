# frozen_string_literal: true

module Ghdb
  module Config
    GHDB_DIR    = '.ghdb'
    CONFIG_PATH = "#{GHDB_DIR}/config.yml"

    def self.db_path
      ENV['GHDB_DB_PATH'] || "#{GHDB_DIR}/ghdb.sqlite"
    end
  end
end
