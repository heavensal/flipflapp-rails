class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :confirmable

  validates :first_name, presence: true
  validates :last_name, presence: true

  after_create :set_username

  def set_username
    self.username = "#{first_name.downcase}#{last_name.upcase.first}#{rand(1000..9999)}"
    self.save!
  end
end
