class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_event_view!, only: [ :show ]
  before_action :authorize_event_owner!, only: [ :edit, :update, :destroy ]

  # GET /events
  #
  # GET /events/home
  def home
  end
  def index
    @events = Event.visible_to(current_user).upcoming
  end


  # GET /events/:id
  def show
    @team_1 = @event.event_teams.first
    @team_2 = @event.event_teams.second
    @bench = @event.event_teams.third
    @event_participant = @event.event_participants.find_by(user: current_user)
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # POST /events
  def create
    @event = Event.new(event_params)
    @event.user = current_user
    if @event.save
      redirect_to @event, notice: "Événement créé avec succès."
    else
      flash.now[:alert] = "Impossible de créer l'événement. Veuillez corriger les erreurs ci-dessous."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /events/:id/edit
  def edit
  end

  # PATCH/PUT /events/:id
  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Événement modifié avec succès."
    else
      flash.now[:alert] = "Impossible de modifier l'événement. Veuillez corriger les erreurs ci-dessous."
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    if @event.destroy
      redirect_to authenticated_root_path, alert: "L'événement a bien été supprimé."
    else
      redirect_to @event, alert: "Impossible de supprimer l'événement."
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_event_view!
    return if @event.viewable_by?(current_user)

    redirect_to authenticated_root_path, alert: t("events.authorization.inaccessible")
  end

  def authorize_event_owner!
    return if @event.am_i_the_author?(current_user)

    redirect_to @event, alert: t("events.authorization.owner_required")
  end

  def event_params
    params.require(:event).permit(:title, :description, :location, :start_time, :number_of_participants, :price, :is_private)
  end
end

# create_table "events", force: :cascade do |t|
#   t.string "title", null: false
#   t.text "description"
#   t.string "location", null: false
#   t.datetime "start_time", null: false
#   t.integer "number_of_participants", default: 10, null: false
#   t.decimal "price", precision: 10, scale: 2, default: "10.0", null: false
#   t.boolean "is_private", default: true, null: false
#   t.bigint "user_id", null: false
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
#   t.index ["user_id"], name: "index_events_on_user_id"
# end
