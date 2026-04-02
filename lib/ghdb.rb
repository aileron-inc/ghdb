# frozen_string_literal: true

require 'active_record'
require 'fileutils'
require 'front_matter_parser'

require_relative 'ghdb/version'
require_relative 'ghdb/config'
require_relative 'ghdb/schema'
require_relative 'ghdb/record'
require_relative 'ghdb/concerns/ulid_primary_key'
require_relative 'ghdb/repository'
require_relative 'ghdb/blob_entry'
require_relative 'ghdb/commands/init'
require_relative 'ghdb/commands/new'
require_relative 'ghdb/commands/build'
require_relative 'ghdb/commands/push'
require_relative 'ghdb/commands/info'
require_relative 'ghdb/commands/pull'
require_relative 'ghdb/commands/cleanup'

module Ghdb
  class Error < StandardError; end

  def self.connect(database:)
    Record.establish_connection(
      adapter: 'sqlite3',
      database: database
    )
    Record.connection.tap do |conn|
      Schema.create(conn)
    end
  end

  # Rails で database.yml を使う場合はこちら
  # config/database.yml に ghdb: adapter: sqlite3, database: db/ghdb.sqlite を追加
  # Ghdb.connect は不要
end
