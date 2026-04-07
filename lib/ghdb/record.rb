# frozen_string_literal: true

module Ghdb
  class Record < ActiveRecord::Base
    self.abstract_class = true

    # Rails 環境では database.yml の :ghdb を使う
    # CLI 環境では Ghdb.connect(database:) で establish_connection する
    if defined?(Rails)
      ActiveSupport.on_load(:after_initialize) do
        Ghdb::Record.connects_to database: { writing: :ghdb, reading: :ghdb }
      end
    end
  end
end
