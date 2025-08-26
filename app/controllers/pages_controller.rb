class PagesController < ApplicationController
  def home
    @beta_tester = BetaTester.new
  end
end
