class BetaTestersController < ApplicationController
  def index
    @beta_testers = BetaTester.all
  end

  def show
    @beta_tester = BetaTester.find(params[:id])
  end

  def new
    @beta_tester = BetaTester.new
  end

  def create
    @beta_tester = BetaTester.new(beta_tester_params)
    if @beta_tester.save
      redirect_to root_path, notice: "Merci d'avoir rejoint la bêta ! On te tient vite au courant des avancées !"
    else
      render :root_path
    end
  end

  def edit
    @beta_tester = BetaTester.find(params[:id])
  end

  def update
    @beta_tester = BetaTester.find(params[:id])
    if @beta_tester.update(beta_tester_params)
      redirect_to @beta_tester, notice: "Beta tester was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @beta_tester = BetaTester.find(params[:id])
    @beta_tester.destroy
    redirect_to beta_testers_path, notice: "Beta tester was successfully destroyed."
  end

  private

  def beta_tester_params
    params.require(:beta_tester).permit(:first_name, :last_name, :email, :phone, :favorite_social_network, :social_network_name, :age)
  end
end
