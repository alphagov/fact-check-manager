class ChangeNullConstraintsOnRequests < ActiveRecord::Migration[8.1]
  def change
    change_table :requests do |t|
      t.change_null :current_content, false
      t.change_null :deadline, false
    end
  end
end
