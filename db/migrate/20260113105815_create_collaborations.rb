class CreateCollaborations < ActiveRecord::Migration[8.0]
  def change
    create_table :collaborations do |t|
      t.belongs_to :user
      t.belongs_to :request
      t.string :role

      t.timestamps
    end

    add_index :collaborations, [:user_id, :request_id], unique: true
  end
end
