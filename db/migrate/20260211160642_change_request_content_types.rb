class ChangeRequestContentTypes < ActiveRecord::Migration[8.0]
  def change
    change_column(:requests, :previous_content, :json, using: 'previous_content::json')
    change_column(:requests, :current_content, :json, using: 'current_content::json')
  end
end
