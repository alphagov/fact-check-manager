class CleanupRequestsContentColumns < ActiveRecord::Migration[8.0]
  change_table(:requests, bulk: true) do |t|
    # Remove old text columns, now that data has been converted to json
    t.remove :current_content, type: :text
    t.remove :previous_content, type: :text

    # Rename new columns to replace removed column names
    t.rename :json_current_content, :current_content
    t.rename :json_previous_content, :previous_content
  end
end
