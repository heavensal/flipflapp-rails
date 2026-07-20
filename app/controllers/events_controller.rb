class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[show edit update destroy]
  before_action :authorize_event_view!, only: :show
  before_action :authorize_event_owner!, only: %i[edit update destroy]

  def home
  end

  def index
    @events = Event.visible_to(current_user)
                   .with_countable_participants_count
                   .upcoming
                   .includes(:user)
  end

  def show
    teams = @event.event_teams.includes(event_participants: :user).index_by(&:slot)
    @team_1 = teams["team_one"]
    @team_2 = teams["team_two"]
    @bench = teams["bench"]
    @event_participant = @event.event_participants.find_by(user: current_user)
  end

  def new
    @event = Event.new(start_time: 1.day.from_now.change(hour: 20, min: 0))
  end

  def create
    @event = current_user.events.build(event_params)
    if @event.save
      redirect_to @event, notice: t("events.flash.create.success")
    else
      flash.now[:alert] = t("events.flash.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: t("events.flash.update.success")
    else
      flash.now[:alert] = t("events.flash.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.destroy
      redirect_to authenticated_root_path, alert: t("events.flash.destroy.success")
    else
      redirect_to @event, alert: t("events.flash.destroy.failure")
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_event_view!
    return if @event.viewable_by?(current_user)

    redirect_to authenticated_root_path, alert: t("events.flash.authorization.inaccessible")
  end

  def authorize_event_owner!
    return if @event.am_i_the_author?(current_user)

    redirect_to @event, alert: t("events.flash.authorization.owner_required")
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :location, :start_time, :number_of_participants,
      :price, :is_private, :latitude, :longitude
    )
  end
end
