class HardenCollaborationConstraints < ActiveRecord::Migration[8.1]
  def up
    change_column_null :collaborations, :user_id, false
    change_column_null :collaborations, :request_id, false

    add_foreign_key :collaborations, :users
    add_foreign_key :collaborations, :requests

    remove_index :collaborations, :user_id
  end

  def down
    add_index :collaborations, :user_id

    remove_foreign_key :collaborations, :users
    remove_foreign_key :collaborations, :requests

    change_column_null :collaborations, :request_id, true
    change_column_null :collaborations, :user_id, true
  end
end