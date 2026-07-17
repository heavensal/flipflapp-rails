# frozen_string_literal: true

class ChangeNotificationsKindDefault < ActiveRecord::Migration[8.0]
  def change
    # 0 was `:created` (removed). Require an explicit kind on insert.
    change_column_default :notifications, :kind, from: 0, to: nil
  end
end
