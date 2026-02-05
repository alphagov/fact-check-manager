class ChangeDefaultRequestStatusToNew < ActiveRecord::Migration[8.0]
  def change
    change_column :requests, :status, :string, default: "new", null: false
  end
end
