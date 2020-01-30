class Poll < ApplicationRecord
  belongs_to :event
  has_many :fields
  validates :question, presence: true
  validates :option, presence: true
end
