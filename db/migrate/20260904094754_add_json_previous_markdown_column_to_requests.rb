class AddJsonPreviousMarkdownColumnToRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :requests, :previous_markdown, :json
    Request.reset_column_information
  end
end
