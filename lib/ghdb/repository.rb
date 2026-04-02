# frozen_string_literal: true

module Ghdb
  class Repository < Record
    include Concerns::UlidPrimaryKey

    has_many :blob_entries, dependent: :destroy

    validates :owner, presence: true
    validates :name, presence: true
    validates :owner, uniqueness: { scope: :name }
  end
end
