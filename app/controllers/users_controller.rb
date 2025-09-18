class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
    @friendship = Friendship.find_by(sender: current_user, receiver: @user) || Friendship.find_by(sender: @user, receiver: current_user)
  end

  def me
    @user = current_user
    render :show
  end
end
