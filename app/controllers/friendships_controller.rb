class FriendshipsController < ApplicationController
  before_action :authenticate_user!

  TABS = %w[friends received sent declined].freeze

  def index
    @accepted_friendships = current_user.accepted_friendships.includes(:sender, :receiver)
    @sent_friendships = current_user.pending_sent_friendships.includes(:receiver)
    @received_friendships = current_user.pending_received_friendships.includes(:sender)
    @declined_friendships = current_user.declined_received_friendships.includes(:sender)
    @tab = resolve_tab
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

    unless friendship.receiver == current_user && friendship.status == "pending"
      redirect_to friendships_path, alert: t("friendships.flash.update.failure")
      return
    end

    if params[:status] == "declined"
      if friendship.decline
        redirect_to friendships_path(tab: "declined"), alert: t("friendships.flash.update.declined")
      else
        redirect_to friendships_path, alert: t("friendships.flash.update.failure")
      end
    elsif friendship.accept
      redirect_to friendships_path(tab: "friends"), notice: t("friendships.flash.update.success", name: friendship.sender.first_name)
    else
      redirect_to friendships_path, alert: t("friendships.flash.update.failure")
    end
  end

  def destroy
    friendship = Friendship.find(params[:id])

    if friendship.receiver == current_user && friendship.status == "declined"
      friendship.destroy
      redirect_to friendships_path(tab: "friends"), notice: t("friendships.flash.destroy.removed_declined")

    elsif (friendship.sender == current_user || friendship.receiver == current_user) && friendship.status == "accepted"
      other_user = friendship.sender == current_user ? friendship.receiver : friendship.sender
      friendship.destroy
      redirect_to friendships_path(tab: "friends"), alert: t("friendships.flash.destroy.unfriended", name: other_user.first_name)

    elsif friendship.sender == current_user && friendship.status == "pending"
      friendship.destroy
      redirect_to friendships_path(tab: "sent"), alert: t("friendships.flash.destroy.cancelled")

    else
      redirect_back fallback_location: friendships_path, alert: t("friendships.flash.destroy.unauthorized")
    end
  end

  private

  def resolve_tab
    tab = TABS.include?(params[:tab]) ? params[:tab] : "friends"
    return "friends" if tab == "declined" && @declined_friendships.empty?

    tab
  end
end
