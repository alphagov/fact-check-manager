class AddJsonPreviousContentColumnToRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :requests, :json_previous_content, :json
    Request.reset_column_information

    # Convert old data and move it to this column
    Request.find_each do |request|
      if request.previous_content.present?
        json_payload = { body: request.previous_content }
        request.update_columns(json_previous_content: json_payload)
      end
    end
  end

  def down
    remove_column :requests, :json_previous_content
  end
end
