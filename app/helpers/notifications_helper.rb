module NotificationsHelper
  def notification_message(notification)
    case notification.kind
    # when "created"
    #   "L'événement '#{notification.notifiable.title}' a été créé."
    when "joined"
      "#{notification.payload['player']} a rejoint ton événement \"#{notification.payload['title']}\"."
    when "left"
      "#{notification.payload['player']} a quitté ton événement \"#{notification.payload['title']}\"."
    when "updated"
      changes = notification.payload["changes"] || {}
      details = changes.map do |field, (old_val, new_val)|
        case field
        when "start_time"
          "⏰ Date : #{human_future_date(old_val)} → #{human_future_date(new_val)}"
        when "price"
          "💰 Prix : #{old_val}€ → #{new_val}€"
        when "number_of_participants"
          "👥 Places : #{old_val} → #{new_val}"
        when "title"
          "🏷️ Titre : « #{old_val} » → « #{new_val} »"
        when "location"
          "📍 Lieu : « #{old_val} » → « #{new_val} »"
        else
          "#{field.humanize} : #{old_val} → #{new_val}"
        end
      end.join(", ")
    when "canceled"
      "L'événement \"#{notification.payload['title']}\" prévu #{human_future_date(notification.payload['start_time'])} et organisé par #{notification.payload['author']} a été annulé."
    else
      "Vous avez une nouvelle notification."
    end
  end

  def notification_icon(kind)
    case kind
    when "created" then "🆕"
    when "updated" then "✏️"
    when "canceled" then "❌"
    when "joined" then "👤"
    when "left" then "🚪"
    when "invited" then "📨"
    when "reminder" then "⏰"
    else "🔔"
    end
  end
end
