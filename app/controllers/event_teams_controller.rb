class EventTeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_event_team
  before_action :authorize_participant!
  before_action :authorize_countable_team!

  def edit
    redirect_to @event
  end

  def update
    if @event_team.update(event_team_params)
      redirect_to @event, notice: t("event_team.update.success")
    else
      redirect_to @event, alert: @event_team.errors.full_messages.to_sentence
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
    return if @event.viewable_by?(current_user)

    redirect_to authenticated_root_path, alert: t("events.authorization.inaccessible")
  end

  def set_event_team
    @event_team = @event.event_teams.find(params[:id])
  end

  def authorize_participant!
    return if @event.in_this_event?(current_user)

    redirect_to @event, alert: t("event_team.authorization.participant_required")
  end

  def authorize_countable_team!
    return if @event_team.countable?

    redirect_to @event, alert: t("event_team.authorization.bench_not_renamable")
  end

  def event_team_params
    params.require(:event_team).permit(:label)
  end
end
