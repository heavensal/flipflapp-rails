class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  # Contrôleur pour la gestion des amitiés
  # Les actions CRUD peuvent être ajoutées ici selon les besoins

  def index
    @accepted_friendships = current_user.accepted_friendships.includes(:sender, :receiver)
    @sent_friendships = current_user.sent_friendships.includes(:receiver)
    @received_friendships = current_user.received_friendships.includes(:sender)
  end

  def search
    @q = User.users_without_friendship(current_user).ransack(params[:q])

    @users =
      if params[:q].present?
        @q.result.select(:id, :first_name, :last_name, :username, :email).distinct
      else
        User.none
      end
  end



  def create
    @user = User.find(params[:user_id])
    friendship = current_user.pending_requests.build(sender: current_user, receiver: @user, status: "pending")
    if friendship.save
      redirect_to user_path(@user), notice: "Demande d'amitié envoyée à #{@user.first_name}."
    else
      redirect_to user_path(@user), alert: "Impossible d'envoyer la demande d'amitié."
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
