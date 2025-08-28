class BetaTester < ApplicationRecord
  validates :first_name, presence: { message: "Le prénom est requis" }
  validates :last_name, presence: { message: "Le nom est requis" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Format d'email invalide" }
  validates :email, uniqueness: { message: "Cet email existe déjà dans notre base de données" }
  validates :phone, presence: true, format: { with: /\A\+?(\d.*){3,}\z/, message: "doit être un numéro de téléphone valide" }
  validates :favorite_social_network, presence: true, inclusion: { in: %w[ Snapchat Facebook Telegram Whatsapp Twitter Instagram ], message: "Veuillez sélectionner un réseau social valide" }
  validates :social_network_name, presence: { message: "Le nom d'utilisateur correspondant au réseau social sélectionné est requis" }
  validates :age, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
