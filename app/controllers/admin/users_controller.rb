module Admin
  class UsersController < BaseController
    include Resourceful
    admin_resource :users

    def send_password_reset
      @record = find_record
      @record.send_reset_password_instructions
      redirect_to admin_user_path(@record), notice: t("admin.flash.users.password_reset_sent")
    end

    private

    def resource_params
      keys = resource.writable_columns
      keys += %w[password password_confirmation] if action_name == "create"
      params.require(:user).permit(*keys)
    end
  end
end
