class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :confirmable

  validates :first_name, presence: true
  validates :last_name, presence: true

  before_create :set_uid_and_provider
  after_create :set_username

  has_many :events, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :notifications, dependent: :destroy

  ########################## RECHERCHE AVEC RANSACK ##########################
  def self.ransackable_attributes(auth_object = nil)
    %w(first_name last_name email username) + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
  ############################################################################

  ########################## FRIENDSHIPS EN ATTENTE ##########################
  # Friendships où l'user est sender et c'est pending
  has_many :sent_friendships,
          -> { where(friendships: { status: "pending" }) },
          class_name: "Friendship",
          foreign_key: "sender_id",
          dependent: :destroy

  # Friendships où l'user est receiver et c'est pending
  has_many :received_friendships,
          -> { where(friendships: { status: "pending" }) },
          class_name: "Friendship",
          foreign_key: "receiver_id",
          dependent: :destroy

  ########################## FRIENDSHIPS ACCEPTÉES ##########################
  # Requêtes d'amitié envoyées par l'user (sender)
  # Friendships acceptées envoyées
  has_many :sent_accepted_friendships,
          -> { where(status: "accepted") },
          class_name: "Friendship",
          foreign_key: "sender_id",
          dependent: :destroy

  # Friendships acceptées reçues
  has_many :received_accepted_friendships,
          -> { where(status: "accepted") },
          class_name: "Friendship",
          foreign_key: "receiver_id",
          dependent: :destroy

  # Méthode pour combiner les deux
  def accepted_friendships
    Friendship.where(status: "accepted")
              .where("sender_id = :id OR receiver_id = :id", id: self.id)
  end

  # Amis qui ne sont pas des event_participants
  def get_my_friends_but_not_participants(event)
    friends = accepted_friendships.map do |friendship|
      friendship.sender == self ? friendship.receiver : friendship.sender
    end
    friends - event.event_participants.map(&:user)
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

  ########################## FRIENDSHIPS EN ATTENTE ##########################

  # Toutes les requêtes d'amitié en attente (envoyées et reçues)
  def pending_requests
    Friendship.where(status: "pending")
              .where("sender_id = :id OR receiver_id = :id", id: self.id)
  end

  ###########################################################################


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
