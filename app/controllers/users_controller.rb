class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
    @friendship = current_user.friendship_with(@user)
  end

  def me
    @user = current_user
    render :show
  end
end
