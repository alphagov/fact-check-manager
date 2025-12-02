class Placeholder < ActiveRecord::Migration[7.2]
  def change
    create_table :placeholder do |t|
      t.text :placeholder
    end
  end
end
