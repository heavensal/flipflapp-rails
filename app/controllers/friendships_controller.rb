class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  # Contrôleur pour la gestion des amitiés
  # Les actions CRUD peuvent être ajoutées ici selon les besoins

  def index
    @accepted_friendships = current_user.accepted_friendships.includes(:sender, :receiver)
    @sent_friendships = current_user.sent_friendships.includes(:receiver)
    @received_friendships = current_user.received_friendships.includes(:sender)
  end

  def create
    receiver = User.find(params[:id])
    friendship = current_user.pending_requests.build(receiver: receiver, status: "pending")
    @user = receiver
    if friendship.save
      redirect_to users_path(@user), notice: "Demande d'amitié envoyée."
    else
      redirect_to users_path(@user), alert: "Impossible d'envoyer la demande d'amitié."
    end
  end

  def update
    friendship = Friendship.find(params[:id])
    @user = friendship.sender
    if friendship.receiver == current_user && friendship.update(status: "accepted")
      redirect_to friendships_path, notice: "Vous êtes maintenant amis avec #{@user.first_name}."
    else
      redirect_to friendships_path, alert: "Impossible d'accepter la demande d'amitié."
    end
  end

  def destroy
    friendship = Friendship.find(params[:id])

    # 1er cas : current_user est le receiver et refuse la demande (pending)
    if friendship.receiver == current_user && friendship.status == "pending"
      friendship.destroy
      redirect_to friendships_path, notice: "Demande d'amitié refusée."

    # 2ème cas : current_user est sender ou receiver et l'amitié est acceptée (suppression d'ami)
    elsif (friendship.sender == current_user || friendship.receiver == current_user) && friendship.status == "accepted"
      other_user = friendship.sender == current_user ? friendship.receiver : friendship.sender
      friendship.destroy
      redirect_to friendships_path, notice: "Vous n'êtes plus ami avec #{other_user.first_name}."

    # 3ème cas : current_user est le sender et annule sa demande (pending)
    elsif friendship.sender == current_user && friendship.status == "pending"
      friendship.destroy
      redirect_to friendships_path, notice: "Demande d'amitié annulée."

    else
      redirect_to friendships_path, alert: "Action non autorisée."
    end
  end
end
