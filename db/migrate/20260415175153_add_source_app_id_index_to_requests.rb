class AddSourceAppIdIndexToRequests < ActiveRecord::Migration[8.1]
  def change
    remove_index :requests, column: :source_id
    add_index :requests, [:source_app, :source_id, :created_at], unique: true, name: "index_requests_on_source_app_id_source_id_and_created_at"
  end
end
