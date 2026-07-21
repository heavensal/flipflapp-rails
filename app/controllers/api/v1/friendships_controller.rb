# frozen_string_literal: true

module Api
  module V1
    class FriendshipsController < BaseController
      def index
        render json: {
          accepted: FriendshipSerializer.new(
            current_user.accepted_friendships.includes(:sender, :receiver)
          ).serializable_hash,
          sent: FriendshipSerializer.new(
            current_user.pending_sent_friendships.includes(:receiver)
          ).serializable_hash,
          received: FriendshipSerializer.new(
            current_user.pending_received_friendships.includes(:sender)
          ).serializable_hash,
          declined: FriendshipSerializer.new(
            current_user.declined_received_friendships.includes(:sender)
          ).serializable_hash
        }
      end

      def search
        q = User.users_without_friendship(current_user).ransack(params[:q])
        users = params[:q].present? ? q.result.select(:id, :first_name, :last_name, :username).distinct : User.none
        render json: UserSerializer.new(users).serializable_hash
      end

      def create
        user = User.find(params[:user_id])
        friendship = current_user.sent_friendships.build(receiver: user, status: "pending")
        if friendship.save
          render json: FriendshipSerializer.new(friendship).serializable_hash, status: :created
        else
          render_validation_errors(friendship)
        end
      end

      def update
        friendship = Friendship.find(params[:id])
        unless friendship.receiver == current_user && friendship.status == "pending"
          return render_forbidden
        end

        if params[:status] == "declined"
          return render_forbidden unless friendship.decline

          render json: FriendshipSerializer.new(friendship).serializable_hash
        elsif friendship.accept
          render json: FriendshipSerializer.new(friendship).serializable_hash
        else
          render_validation_errors(friendship)
        end
      end

      def destroy
        friendship = Friendship.find(params[:id])
        allowed =
          (friendship.receiver == current_user && friendship.status == "declined") ||
          ((friendship.sender == current_user || friendship.receiver == current_user) && friendship.status == "accepted") ||
          (friendship.sender == current_user && friendship.status == "pending")

        return render_forbidden unless allowed

        friendship.destroy!
        head :no_content
      end
    end
  end
end
