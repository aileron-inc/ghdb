# frozen_string_literal: true

require 'ulid'

module Ghdb
  module Concerns
    module UlidPrimaryKey
      extend ActiveSupport::Concern

      included do
        self.primary_key = 'id'
        before_create { self.id = ULID.generate }
      end
    end
  end
end
