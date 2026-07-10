class ChangeZendeskNumberOnRequestsToString < ActiveRecord::Migration[8.1]
  def up
    change_column :requests, :zendesk_number, :string
  end

  def down
    change_column :requests, :zendesk_number, :integer, using: "zendesk_number::integer"
  end
end
