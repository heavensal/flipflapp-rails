class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  def index
    @accepted_friendships = current_user.accepted_friendships.includes(:sender, :receiver)
    @sent_friendships = current_user.pending_sent_friendships.includes(:receiver)
    @received_friendships = current_user.pending_received_friendships.includes(:sender)
  end

  def search
    @q = User.users_without_friendship(current_user).ransack(params[:q])

    @users =
      if params[:q].present?
        @q.result.select(:id, :first_name, :last_name, :username).distinct
      else
        User.none
      end
  end

  def create
    @user = User.find(params[:user_id])
    friendship = current_user.sent_friendships.build(receiver: @user, status: "pending")
    if friendship.save
      redirect_to user_path(@user), notice: t("friendships.flash.create.success", name: @user.first_name)
    else
      redirect_to user_path(@user), alert: t("friendships.flash.create.failure")
    end
  end

  def update
    friendship = Friendship.find(params[:id])
    @user = friendship.sender
    if friendship.receiver == current_user && friendship.update(status: "accepted")
      redirect_to friendships_path, notice: t("friendships.flash.update.success", name: @user.first_name)
    else
      redirect_to friendships_path, alert: t("friendships.flash.update.failure")
    end
  end

  def destroy
    friendship = Friendship.find(params[:id])

    if friendship.receiver == current_user && friendship.status == "pending"
      friendship.destroy
      redirect_back fallback_location: friendships_path, alert: t("friendships.flash.destroy.declined")

    elsif (friendship.sender == current_user || friendship.receiver == current_user) && friendship.status == "accepted"
      other_user = friendship.sender == current_user ? friendship.receiver : friendship.sender
      friendship.destroy
      redirect_back fallback_location: friendships_path, alert: t("friendships.flash.destroy.unfriended", name: other_user.first_name)

    elsif friendship.sender == current_user && friendship.status == "pending"
      friendship.destroy
      redirect_back fallback_location: friendships_path, alert: t("friendships.flash.destroy.cancelled")

    else
      redirect_back fallback_location: friendships_path, alert: t("friendships.flash.destroy.unauthorized")
    end
  end
end
