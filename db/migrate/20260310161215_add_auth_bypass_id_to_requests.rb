class AddAuthBypassIdToRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :requests, :auth_bypass_id, :uuid, default: "gen_random_uuid()", null: false
  end
end
