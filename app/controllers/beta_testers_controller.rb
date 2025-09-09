class BetaTestersController < ApplicationController
  def create
    @beta_tester = BetaTester.new(beta_tester_params)
    sleep 20
    if @beta_tester.save
      redirect_to unauthenticated_root_path, notice: "Merci d'avoir rejoint la bêta ! On te tient vite au courant des avancées !"
    else
      flash.now[:alert] = "Veuillez corriger les erreurs ci-dessous."
      # @beta_tester = BetaTester.new
      render "pages/home", status: :unprocessable_entity
    end
  end

  private

  def beta_tester_params
    params.require(:beta_tester).permit(:first_name, :last_name, :email, :phone, :favorite_social_network, :social_network_name, :age)
  end
end
