class AddReasonForChangeAndZendeskNumberToRequests < ActiveRecord::Migration[8.1]
  def change
    change_table :requests, bulk: true do |t|
      t.string :reason_for_change
      t.integer :zendesk_number
    end
  end
end
