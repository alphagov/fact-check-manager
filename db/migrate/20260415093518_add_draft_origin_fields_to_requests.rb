class AddDraftOriginFieldsToRequests < ActiveRecord::Migration[8.1]
  def change
    change_table :requests, bulk: true do |t|
      t.uuid :draft_content_id
      t.uuid :draft_auth_bypass_id
      t.string :draft_slug
    end
  end
end
