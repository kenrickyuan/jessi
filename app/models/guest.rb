class Guest < ApplicationRecord
  belongs_to :event
  has_many :expenses
  validates :name, presence: true

  before_save :capitalize_guest_name

  def capitalize_guest_name
    self.name = self.name.capitalize
  end
end
