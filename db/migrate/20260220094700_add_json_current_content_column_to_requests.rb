class AddJsonCurrentContentColumnToRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :requests, :json_current_content, :json
    Request.reset_column_information

    # Convert old data and move it to this column
    Request.find_each do |request|
      if request.current_content.present?
        json_payload = { body: request.current_content }
        request.update_columns(json_current_content: json_payload)
      end
    end
  end

  def down
    remove_column :requests, :json_current_content
  end
end
