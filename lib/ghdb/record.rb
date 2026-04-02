# frozen_string_literal: true

module Ghdb
  class Record < ActiveRecord::Base
    self.abstract_class = true

    # Rails 環境では database.yml の :ghdb を使う
    # CLI 環境では Ghdb.connect(database:) で establish_connection する
    connects_to database: { writing: :ghdb, reading: :ghdb } if defined?(Rails)
  end
end
