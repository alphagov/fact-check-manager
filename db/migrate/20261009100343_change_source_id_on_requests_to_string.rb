class ChangeSourceIdOnRequestsToString < ActiveRecord::Migration[8.1]
  def up
    change_column :requests, :source_id, :string
  end

  def down
    change_column :requests, :source_id, :uuid, using: "source_id::uuid"
  end
end
