class EventsController < ApplicationController
  before
  # GET /events
  def index
    @events = Event.all
  end

  # GET /events/:id
  def show
    @event = Event.find(params[:id])
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
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new
    end
  end

  # GET /events/:id/edit
  def edit
    @event = Event.find(params[:id])
  end

  # PATCH/PUT /events/:id
  def update
    @event = Event.find(params[:id])
    if @event.update(event_params)
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /events/:id
  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to events_url, notice: "Event was successfully destroyed."
  end

  private

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
