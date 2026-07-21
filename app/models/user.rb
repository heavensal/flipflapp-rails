require "securerandom"

class User < ApplicationRecord
  ROLES = %w[player admin].freeze

  mount_uploader :avatar, AvatarUploader
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :confirmable,
          :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider, case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  before_validation :set_uid_and_provider
  before_validation :set_username, on: :create

  has_many :events, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :notifications, dependent: :destroy

  ########################## RECHERCHE AVEC RANSACK ##########################
  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name username] + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  ############################################################################

  def self.find_for_confirmation_email(email)
    normalized_email = email.to_s.strip.downcase
    return if normalized_email.blank?

    where("LOWER(email) = :email OR LOWER(unconfirmed_email) = :email", email: normalized_email).first
  end

  has_many :sent_friendships,
          class_name: "Friendship",
          foreign_key: "sender_id",
          inverse_of: :sender,
          dependent: :destroy

  has_many :received_friendships,
          class_name: "Friendship",
          foreign_key: "receiver_id",
          inverse_of: :receiver,
          dependent: :destroy

  ########################## FRIENDSHIPS EN ATTENTE ##########################
  has_many :pending_sent_friendships,
          -> { pending },
          class_name: "Friendship",
          foreign_key: "sender_id",
          inverse_of: :sender

  has_many :pending_received_friendships,
          -> { pending },
          class_name: "Friendship",
          foreign_key: "receiver_id",
          inverse_of: :receiver

  ########################## FRIENDSHIPS ACCEPTÉES ##########################
  has_many :accepted_sent_friendships,
          -> { accepted },
          class_name: "Friendship",
          foreign_key: "sender_id",
          inverse_of: :sender

  has_many :accepted_received_friendships,
          -> { accepted },
          class_name: "Friendship",
          foreign_key: "receiver_id",
          inverse_of: :receiver

  has_many :declined_received_friendships,
          -> { declined },
          class_name: "Friendship",
          foreign_key: "receiver_id",
          inverse_of: :receiver

  # Méthode pour combiner les deux
  def accepted_friendships
    Friendship.where(status: "accepted")
              .where("sender_id = :id OR receiver_id = :id", id: self.id)
  end

  # Accepted friends who are not participants and have no pending Invitation
  def get_my_friends_but_not_participants(event)
    friend_ids = accepted_friendships.pluck(:sender_id, :receiver_id).flatten.uniq - [ id ]
    participant_ids = event.event_participants.pluck(:user_id)
    invited_ids = event.invitations.pluck(:user_id)

    User.where(id: friend_ids - participant_ids - invited_ids)
  end



  # Retrouver tous les users qui n'ont aucun friendship avec moi
  def self.users_without_friendship(current_user)
    # Récupérer tous les user_ids avec lesquels l'utilisateur actuel a une amitié
    friendship_user_ids = Friendship.where("sender_id = :id OR receiver_id = :id", id: current_user.id)
                                    .pluck(:sender_id, :receiver_id).flatten.uniq

    # Ajouter l'ID de l'utilisateur actuel pour l'exclure des résultats
    friendship_user_ids << current_user.id

    # Trouver tous les utilisateurs dont l'ID n'est pas dans la liste des amitiés
    User.where.not(id: friendship_user_ids)
  end

  def friendship_with(other_user)
    return if other_user.blank?

    Friendship.where(sender: self, receiver: other_user)
              .or(Friendship.where(sender: other_user, receiver: self))
              .first
  end

  # Cette personne n'a aucun lien d'amitié avec moi
  def has_no_friendship_with?(other_user)
    friendship_with(other_user).blank?
  end

  # Cette personne m'a envoyé une demande d'amitié
  def has_pending_request_from?(other_user)
    friendship = friendship_with(other_user)
    friendship.present? && friendship.sender_id == other_user.id && friendship.receiver_id == id && friendship.status == "pending"
  end

  # J'ai envoyé une demande d'amitié à cette personne
  def has_asked_to_be_friend_with?(other_user)
    friendship = friendship_with(other_user)
    friendship.present? && friendship.sender_id == id && friendship.receiver_id == other_user.id && friendship.status == "pending"
  end

  # Cette personne est déjà mon amie
  def is_friend_with?(other_user)
    friendship_with(other_user)&.status == "accepted"
  end

  ########################## FRIENDSHIPS EN ATTENTE ##########################

  # Toutes les requêtes d'amitié en attente (envoyées et reçues)
  def pending_requests
    Friendship.where(status: "pending")
              .where("sender_id = :id OR receiver_id = :id", id: self.id)
  end

  ###########################################################################


  def set_username
    return if username.present?

    base = username_base

    loop do
      number = rand(0..9999).to_s.rjust(4, "0")
      candidate = "#{base}##{number}"
      next if User.where("LOWER(username) = ?", candidate.downcase).exists?

      self.username = candidate
      break
    end
  end

  def set_uid_and_provider
    self.provider = "email" if provider.blank?
    self.uid = email if provider == "email" && email.present?
  end

  private

  def username_base
    base = "#{first_name.to_s.parameterize(separator: "")}#{last_name.to_s.first.to_s.downcase}"
    base.presence || "user"
  end
end
