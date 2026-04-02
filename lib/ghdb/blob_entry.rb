# frozen_string_literal: true

module Ghdb
  class BlobEntry < Record
    include Concerns::UlidPrimaryKey

    belongs_to :repository

    validates :path, presence: true
    validates :sha, presence: true
    validates :path, uniqueness: { scope: :repository_id }
  end
end
