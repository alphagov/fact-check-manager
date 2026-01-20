class CreateRequests < ActiveRecord::Migration[8.0]
  def change
    # Bigint ID column is added by default
    create_table :requests do |t|
      enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
      t.uuid :source_id, index: true, null: false
      t.string :source_app, null: false
      t.string :source_url
      t.string :source_title
      t.string :requester_name, null: false
      t.string :requester_email, null: false
      t.string :status, null: false, default: 'new'
      t.text :previous_content
      t.text :current_content, null: false
      t.datetime :deadline

      t.timestamps
    end

    add_index :requests, :created_at
  end
end
