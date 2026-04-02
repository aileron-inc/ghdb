# frozen_string_literal: true

module Ghdb
  module Schema
    def self.create(connection)
      connection.create_table :repositories, id: false, if_not_exists: true do |t|
        t.string :id, null: false, primary_key: true
        t.string :owner, null: false
        t.string :name, null: false
        t.string :default_branch, null: false, default: 'main'
        t.datetime :synced_at
        t.timestamps
      end

      connection.add_index :repositories, %i[owner name], unique: true, if_not_exists: true

      connection.create_table :blob_entries, id: false, if_not_exists: true do |t|
        t.string :id, null: false, primary_key: true
        t.string :repository_id, null: false
        t.string :path, null: false
        t.string :sha, null: false
        t.text :content
        t.json :frontmatter
        t.timestamps
      end

      connection.add_index :blob_entries, %i[repository_id path], unique: true, if_not_exists: true
    end
  end
end
