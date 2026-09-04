class AddJsonCurrentMarkdownColumnToRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :requests, :current_markdown, :json
    Request.reset_column_information
  end
end
