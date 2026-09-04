class AddJsonCurrentMarkdownColumnToRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :requests, :current_markdown_col, :json
  end
end
