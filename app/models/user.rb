class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :confirmable

  validates :first_name, presence: true
  validates :last_name, presence: true

  before_create :set_uid_and_provider
  after_create :set_username

  def set_username
    self.username = "#{first_name.downcase}#{last_name.upcase.first}#{rand(1000..9999)}"
    self.save!
  end

  def set_uid_and_provider
    if provider.blank? || uid.blank?
      self.provider = "email"
      self.uid = email
    end
  end
end
